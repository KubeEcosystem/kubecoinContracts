import { utf8ToHex } from "lucid-cardano"
import { useCallback, useMemo, useState } from "react"
import { useCardano, utility } from "use-cardano"

import { Inter } from "@next/font/google"

const inter = Inter({ subsets: ["latin"] })

export default function Contract() {
  const {
    lucid,
    isValid,
    showToaster,
    hideToaster,
    account: { address },
  } = useCardano()

  const [message, setMessage] = useState<string>()
  const [isSigning, setIsSigning] = useState(false)

  const signMessage = useCallback(async () => {
    if (!lucid || !address || !message) return

    setIsSigning(true)

    try {
      const payload = utf8ToHex(message)

      const signedMessage = await lucid.newMessage(address, payload).sign()
      const hasSigned: boolean = lucid.verifyMessage(address, payload, signedMessage)

      if (!hasSigned) throw new Error("Could not sign message")

      showToaster("Signed message", message)
      setMessage(undefined)
    } catch (e) {
      if (utility.isError(e)) showToaster("Could not sign message", e.message)
      else if (typeof e === "string") showToaster("Could not sign message", e)
    } finally {
      setIsSigning(false)
    }
  }, [lucid, address, message, showToaster])

  const canSign = useMemo(() => isValid && !isSigning && !!message, [isValid, isSigning, message])

  return (
    <div className="text-center max-w-4xl m-auto text-gray-900 dark:text-gray-100">
      <h1
        style={inter.style}
        className="mb-4 text-4xl font-extrabold tracking-tight leading-none md:text-5xl lg:text-6xl"
      >
        Sign a Contract
      </h1>

      <div style={inter.style} className="my-4 text-center">
        Using Lucid, we can sign a contract on the Cardano blockchain.
      </div>

      <div className="text-left my-8">
        <div className="my-4">
          <label className="flex flex-col w-100">
            <span className="text-sm lowercase mb-1">Contract</span>

            <input
              className="rounded py-1 px-2 text-gray-800 border"
              name="contract"
              placeholder="hash"
              value={message || ""}
              onChange={(e) => setMessage(e.target.value?.toString())}
            />
          </label>
        </div>

        <div className="my-4">
          <button
            disabled={!canSign}
            className="border hover:bg-blue-400 text-white my-4 w-40 py-2 cursor-pointer transition-colors disabled:cursor-not-allowed disabled:text-gray-200 rounded bg-blue-300 disabled:bg-blue-200 dark:bg-white dark:text-gray-800 dark:disabled:bg-white dark:hover:bg-white font-bold uppercase"
            onClick={() => {
              hideToaster()
              signMessage()
            }}
          >
            sign
          </button>

          <div className="italic">
            {isValid === false ? (
              <p>
                <small>connect a wallet to send a transaction</small>
              </p>
            ) : isSigning ? (
              <p>
                <small>Signing...</small>
              </p>
            ) : null}
          </div>
        </div>
      </div>
    </div>
  )
}
