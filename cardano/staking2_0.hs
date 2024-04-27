-- Staking smart contract for token a26022096c6a8052987dabbfa94849ab7886cf0bb7840044e017d5be

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module StakingContract where

import           Control.Monad                (when, unless)
import           Data.Map                     (Map)
import qualified Data.Map                     as Map
import           Data.Text                    (Text, pack)
import           Ledger
import           Ledger.Ada                   as Ada
import           Ledger.Constraints           as Constraints
import           Ledger.Slot                  (Slot)
import qualified Ledger.Slot                  as Slot
import           Ledger.TimeSlot              (SlotRange, slotRangeFrom, slotRangeStart)
import           Ledger.Tx                    (ChainIndexTxOut(..))
import           Ledger.Value                 as Value
import           Playground.Contract
import           Plutus.Contract              hiding (when)
import           Plutus.Contract.StateMachine (StateMachine(..), StateMachineClient(..), StateMachineInstance(..), SMContractError, SMContractInstance)
import qualified Plutus.Contract.StateMachine as SM
import           PlutusTx.Prelude             hiding (Semigroup(..), unless)

-- | The state of a single staking contract instance
data StakingContract = StakingContract
    { owner         :: PubKeyHash    -- ^ Owner of the staking contract
    , tokenAsset    :: AssetClass    -- ^ The token being staked
    , tier          :: StakeTier     -- ^ Staking tier
    , stakeAmount   :: Integer       -- ^ Amount of tokens staked
    , lockPeriod    :: Slot          -- ^ Lock period for the stake
    , withdrawalFee :: Integer       -- ^ Withdrawal fee percentage
    , penaltyRate   :: Integer       -- ^ Penalty rate percentage
    , active        :: Bool          -- ^ Flag indicating if the stake is active
    } deriving (Show, Eq)

-- | Data type representing the staking tiers
data StakeTier = Explorer | Voyager | Believer
    deriving (Show, Eq)

-- | Data type representing different stake transitions
data StakeTransition
    = Stake
    | Withdraw
    deriving (Show, Eq)

-- | Validator for the staking contract
validateStakingContract :: StakingContract -> StakeTransition -> () -> ScriptContext -> Bool
validateStakingContract sc transition _ ctx =
    case transition of
        Stake    -> validateStake sc ctx
        Withdraw -> validateWithdraw sc ctx

-- | Validate stake operation
validateStake :: StakingContract -> ScriptContext -> Bool
validateStake sc ctx =
    let
        info = scriptContextTxInfo ctx
        owner' = owner sc
        amount = stakeAmount sc
        lock = lockPeriod sc
        tier' = tier sc
        active' = active sc
        totalSupply = assetClassValueOf (Value.assetClassValue (tokenAsset sc))
    in
        (isJust (findDatum (Datum $ toBuiltinData owner') info) || active') &&
        traceIfFalse "Owner does not match" (owner' == txSignedBy info) &&
        traceIfFalse "Stake amount must be positive" (amount > 0) &&
        traceIfFalse "Lock period must be in the future" (to (slotRangeStart lock) > txInfoValidRange info) &&
        traceIfFalse "Stake tier must match contract tier" (validateTier tier' amount totalSupply) &&
        traceIfFalse "Stake must be made with correct token" (assetClassValueOf (valuePaidTo info (scriptAddress ctx)) == amount)

-- | Validate withdrawal operation
validateWithdraw :: StakingContract -> ScriptContext -> Bool
validateWithdraw sc ctx =
    let
        info = scriptContextTxInfo ctx
        owner' = owner sc
        amount = stakeAmount sc
        lock = lockPeriod sc
        tier' = tier sc
        active' = active sc
        totalSupply = assetClassValueOf (Value.assetClassValue (tokenAsset sc))
        now = Slot.slot $ txInfoValidRange info
    in
        traceIfFalse "Stake must be active to withdraw" active' &&
        traceIfFalse "Withdrawal must be made by the stake owner" (owner' == txSignedBy info) &&
        traceIfFalse "Lock period must have expired" (now >= lock) &&
        traceIfFalse "Withdraw must be made with correct token" (assetClassValueOf (valuePaidTo info (scriptAddress ctx)) == amount) &&
        traceIfFalse "Stake tier must match contract tier" (validateTier tier' amount totalSupply)

-- | Check if stake amount does not exceed the tier's maximum limit
validateTier :: StakeTier -> Integer -> Integer -> Bool
validateTier Explorer _ _ = True
validateTier Voyager amount totalSupply = amount <= totalSupply * 0.05  -- 5% of total supply
validateTier Believer amount _ = amount <= 1000000  -- 1M KUBE

-- | The stake machine transitions
stakeMachine :: StakeMachine StakingContract StakeTransition
stakeMachine = SM.mkStateMachine Nothing (validateStakingContract) transition
    where
        transition :: StakeTransition -> StakingContract -> () -> ScriptContext -> Bool
        transition _ _ _ _ = True

-- | State machine instance
stakingMachineInstance :: StateMachineInstance StakingContract StakeTransition
stakingMachineInstance = SM.StateMachineInstance
    { SM.smTransition = transition
    , SM.smFinal = isFinal
    , SM.smCheck = const True
    }
    where
        transition :: StateMachine StakingContract StakeTransition -> State StakingContract -> StakeTransition -> Maybe (TxConstraints Void Void, State StakingContract)
        transition (StateMachine _ _ _ _ _ _ _) s Stake =
            Just ( Constraints.mustPayToTheScript () (assetClassValue (tokenAsset $ smState s) (stakeAmount $ smState s))
                 , s { smState = (smState s) { active = True }}
                 )
        transition (StateMachine _ _ _ _ _ _ _) s Withdraw =
            Just ( Constraints.mustPayToPubKey (owner $ smState s) (Ada.lovelaceValueOf $ stakeAmount $ smState s)
                 , s { smState = (smState s) { active = False }}
                 )
        isFinal :: StateMachine StakingContract StakeTransition -> State StakingContract -> Bool
        isFinal _ _ = False

-- | Contract endpoints
type StakingContractSchema =
    Endpoint "stake"    (StakingContract, Slot)
    .\/ Endpoint "withdraw" StakingContract

-- | Staking contract
stakingContract :: SMContractInstance StakingContractSchema StakingContract
stakingContract = SM.mkStateMachineClient $ StateMachineClient
    { SC.scInstance = stakingMachineInstance
    , SC.scEndpoints = StakingContractSchema
        { SC.stake    = stakeEndpoint
        , SC.withdraw = withdrawEndpoint
        }
    }
    where
        -- Stake endpoint
        stakeEndpoint :: (StakingContract, Slot) -> Contract w SMContractError ()
        stakeEndpoint (sc, slot') = do
            when (Slot.fromSlot slot' < Slot.fromSlot (Slot.succ $ lockPeriod sc)) $
                throwError "Lock period must be in the future"
            let val = assetClassValueOf (Value.assetClassValue (tokenAsset sc))
            utxo <- utxosAt (pubKeyHash $ owner sc)
            let funds = Val.coin (Map.findWithDefault mempty val utxo)
            when (funds < stakeAmount sc) $
                throwError "Insufficient funds"
            void $ SM.runStep stakingContract (sc, slot') Stake

        -- Withdraw endpoint
        withdrawEndpoint :: StakingContract -> Contract w SMContractError ()
        withdrawEndpoint sc = do
            let val = assetClassValueOf (Value.assetClassValue (tokenAsset sc))
            utxo <- utxosAt (pubKeyHash $ owner sc)
            let funds = Val.coin (Map.findWithDefault mempty val utxo)
            when (funds < stakeAmount sc) $
                throwError "Insufficient funds"
            void $ SM.runStep stakingContract sc Withdraw

-- | Function to start the staking contract instance
startStakingContract :: StakingContract -> Contract () SMContractError (SMContractInstance StakingContractSchema StakingContract)
startStakingContract sc = SM.runInitialise stakingContract (sc, 0)

-- | Default instances
$(mkKnownCurrencies [])
$(mkSchemaDefinitions ''StakingContractSchema)

