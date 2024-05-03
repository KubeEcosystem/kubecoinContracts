When
    [Case
        (Deposit
            (Role "DepositPool")
            (Role "DepositPool")
            (Token "4b756265436f696e" "KubeCoin")
            (ConstantParam "DepositAmount")
        )
        (When
            [Case
                (Deposit
                    (Role "DepositPool")
                    (Role "DepositPool")
                    (Token "4b756265436f696e" "KubeCoin")
                    (ConstantParam "DepositAmount")
                )
                (Pay
                    (Role "DepositPool")
                    (Party (Role "DepositPool"))
                    (Token "4b756265436f696e" "KubeCoin")
                    (ConstantParam "DepositAmount")
                    Close 
                )]
            777600
            (Pay
                (Role "DepositPool")
                (Party (Role "DepositPool"))
                (Token "4b756265436f696e" "KubeCoin")
                (AddValue
                    (ConstantParam "DepositAmount")
                    (DivValue
                        (MulValue
                            (ConstantParam "DepositAmount")
                            (Constant 5)
                        )
                        (Constant 100)
                    )
                )
                Close 
            )
        )]
    10 Close 
