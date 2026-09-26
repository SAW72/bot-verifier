import { useState, type FormEvent } from "react"
import { formatEther, isAddress, parseEther, type Address, type Hex } from "viem"
import { useAccount, useSendTransaction } from "wagmi"
import { BASE_SEPOLIA_CHAIN_ID } from "./addresses"
import { parseBytes32 } from "./bytes32"
import { errorText } from "./format"
import { resolveWalletChainId } from "./guard"
import {
  ERROR_GLOSSARY,
  MAX_DURATION_SECONDS,
  previewCreateEscrow,
  previewDispute,
  previewOpenDispute,
  previewRefund,
  previewRelease,
  type CallPreview,
} from "./preview"
import { assertSubmitTarget, evaluateEscrowSubmit, submitControl, submitSenderNote } from "./submit"
import { useConnectorChainId } from "./useWalletChain"

function SepoliaSubmit({ preview, escrow, panel }: { preview: CallPreview; escrow: Address; panel: Address }) {
  const account = useAccount()
  const connectorChainId = useConnectorChainId(account.connector, account.isConnected)
  const walletChainId = account.isConnected ? resolveWalletChainId(account.chainId, connectorChainId) : null
  const decision = evaluateEscrowSubmit({ walletConnected: account.isConnected, walletChainId })
  const { sendTransactionAsync, isPending } = useSendTransaction()
  const [txHash, setTxHash] = useState<Hex | null>(null)
  const [submitError, setSubmitError] = useState<string | null>(null)
  const control = submitControl(decision, isPending)

  async function onClick() {
    setSubmitError(null)
    const current = evaluateEscrowSubmit({
      walletConnected: account.isConnected,
      walletChainId: account.isConnected ? resolveWalletChainId(account.chainId, connectorChainId) : null,
    })
    if (!current.ok) {
      setTxHash(null)
      setSubmitError(current.reason)
      return
    }
    try {
      assertSubmitTarget(preview.to, [escrow, panel])
      const hash = await sendTransactionAsync({
        to: preview.to,
        data: preview.calldata,
        value: preview.valueWei,
        chainId: BASE_SEPOLIA_CHAIN_ID,
      })
      setTxHash(hash)
    } catch (cause) {
      setTxHash(null)
      setSubmitError(errorText(cause))
    }
  }

  return (
    <div>
      <p>{submitSenderNote(preview.functionName)}</p>
      <button type="button" data-testid={control.testId} disabled={control.disabled} onClick={() => void onClick()}>
        {control.label}
      </button>
      {submitError ? (
        <p className="bad" role="alert">
          {submitError}
        </p>
      ) : null}
      {txHash ? (
        <p className="mono" data-testid="submit-tx">
          Submitted {txHash}
        </p>
      ) : null}
    </div>
  )
}

function PreviewBlock({ preview, escrow, panel }: { preview: CallPreview | null; escrow: Address; panel: Address }) {
  if (!preview) return null
  return (
    <div className="preview" data-testid="calldata-preview">
      <p>
        Calldata for <strong>{preview.functionName}</strong>. Submit sends it from the connected wallet on Base Sepolia
        only.
      </p>
      <p className="mono">to {preview.to}</p>
      <p>value {formatEther(preview.valueWei)} ETH</p>
      <pre className="calldata">{preview.calldata}</pre>
      <SepoliaSubmit key={preview.calldata} preview={preview} escrow={escrow} panel={panel} />
    </div>
  )
}

function Field({
  id,
  label,
  value,
  onChange,
  hint,
}: {
  id: string
  label: string
  value: string
  onChange: (value: string) => void
  hint?: string
}) {
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      <input id={id} value={value} spellCheck={false} autoComplete="off" onChange={(event) => onChange(event.target.value)} />
      {hint ? <p className="hint">{hint}</p> : null}
    </div>
  )
}

export function FlowPreview({ escrow, panel }: { escrow: Address; panel: Address }) {
  const [error, setError] = useState<string | null>(null)
  const [preview, setPreview] = useState<CallPreview | null>(null)

  function show(next: CallPreview) {
    setError(null)
    setPreview(next)
  }

  return (
    <div>
      <h3>Calldata preview</h3>
      <p className="muted">
        Forms build calldata, then the connected wallet can submit on Base Sepolia (chain id {BASE_SEPOLIA_CHAIN_ID}).
        Ethereum mainnet and Base mainnet are refused. There is no EIP-712 stamp.
      </p>
      <CreateForm
        escrow={escrow}
        onPreview={show}
        onError={(message) => {
          setPreview(null)
          setError(message)
        }}
      />
      <IdForm
        idPrefix="release"
        title="release(escrowId)"
        onSubmit={(escrowId) => show(previewRelease(escrow, escrowId))}
        onError={(message) => {
          setPreview(null)
          setError(message)
        }}
      />
      <IdForm
        idPrefix="refund"
        title="refund(escrowId)"
        onSubmit={(escrowId) => show(previewRefund(escrow, escrowId))}
        onError={(message) => {
          setPreview(null)
          setError(message)
        }}
      />
      <OpenDisputeForm
        panel={panel}
        onPreview={show}
        onError={(message) => {
          setPreview(null)
          setError(message)
        }}
      />
      <DisputeForm
        escrow={escrow}
        onPreview={show}
        onError={(message) => {
          setPreview(null)
          setError(message)
        }}
      />
      {error ? (
        <p className="bad" role="alert">
          {error}
        </p>
      ) : null}
      <PreviewBlock preview={preview} escrow={escrow} panel={panel} />
      <h3>Revert glossary</h3>
      <dl className="glossary">
        {ERROR_GLOSSARY.map((entry) => (
          <div key={entry.name}>
            <dt>{entry.name}</dt>
            <dd>{entry.meaning}</dd>
          </div>
        ))}
      </dl>
    </div>
  )
}

function CreateForm({
  escrow,
  onPreview,
  onError,
}: {
  escrow: Address
  onPreview: (preview: CallPreview) => void
  onError: (message: string) => void
}) {
  const [escrowId, setEscrowId] = useState("")
  const [payee, setPayee] = useState("")
  const [payerBotId, setPayerBotId] = useState("")
  const [payeeBotId, setPayeeBotId] = useState("")
  const [duration, setDuration] = useState("86400")
  const [value, setValue] = useState("0.01")

  function onSubmit(event: FormEvent) {
    event.preventDefault()
    const id = parseBytes32(escrowId)
    const payerBot = parseBytes32(payerBotId)
    const payeeBot = parseBytes32(payeeBotId)
    if (!id || !payerBot || !payeeBot) {
      onError("createEscrow needs three bytes32 values.")
      return
    }
    if (!isAddress(payee)) {
      onError("payee must be an address.")
      return
    }
    const durationSeconds = Number(duration)
    if (!Number.isInteger(durationSeconds) || durationSeconds <= 0 || durationSeconds > MAX_DURATION_SECONDS) {
      onError(`durationSeconds must be a whole number from 1 through ${MAX_DURATION_SECONDS} (30 days).`)
      return
    }
    let valueWei: bigint
    try {
      valueWei = parseEther(value.trim())
    } catch {
      onError("value must be an ETH amount, such as 0.01.")
      return
    }
    if (valueWei <= 0n) {
      onError("value must be greater than 0. The preview still is not sent.")
      return
    }
    onPreview(
      previewCreateEscrow({
        escrow,
        escrowId: id,
        payee,
        payerBotId: payerBot,
        payeeBotId: payeeBot,
        durationSeconds: BigInt(durationSeconds),
        valueWei,
      }),
    )
  }

  return (
    <form onSubmit={onSubmit}>
      <h3>createEscrow</h3>
      <Field id="create-id" label="escrowId" value={escrowId} onChange={setEscrowId} />
      <Field id="create-payee" label="payee" value={payee} onChange={setPayee} />
      <Field id="create-payer-bot" label="payerBotId" value={payerBotId} onChange={setPayerBotId} />
      <Field id="create-payee-bot" label="payeeBotId" value={payeeBotId} onChange={setPayeeBotId} />
      <Field
        id="create-duration"
        label="durationSeconds"
        value={duration}
        onChange={setDuration}
        hint={`Greater than 0 and at most ${MAX_DURATION_SECONDS} (30 days).`}
      />
      <Field
        id="create-value"
        label="value (ETH)"
        value={value}
        onChange={setValue}
        hint="This is msg.value if you submit on Base Sepolia. The connected wallet must be the payer's Vault operator."
      />
      <button type="submit">Build createEscrow calldata</button>
    </form>
  )
}

function IdForm({
  idPrefix,
  title,
  onSubmit,
  onError,
}: {
  idPrefix: string
  title: string
  onSubmit: (escrowId: `0x${string}`) => void
  onError: (message: string) => void
}) {
  const [escrowId, setEscrowId] = useState("")
  return (
    <form
      onSubmit={(event) => {
        event.preventDefault()
        const id = parseBytes32(escrowId)
        if (!id) {
          onError(`${title} needs a bytes32 escrowId.`)
          return
        }
        onSubmit(id)
      }}
    >
      <h3>{title}</h3>
      <Field id={`${idPrefix}-id`} label="escrowId" value={escrowId} onChange={setEscrowId} />
      <button type="submit">Build {title} calldata</button>
    </form>
  )
}

function OpenDisputeForm({
  panel,
  onPreview,
  onError,
}: {
  panel: Address
  onPreview: (preview: CallPreview) => void
  onError: (message: string) => void
}) {
  const [disputeId, setDisputeId] = useState("")
  const [subjectHash, setSubjectHash] = useState("")
  const [reason, setReason] = useState("")

  return (
    <form
      onSubmit={(event) => {
        event.preventDefault()
        const id = parseBytes32(disputeId)
        const subject = parseBytes32(subjectHash)
        if (!id || !subject) {
          onError("openDispute needs disputeId and subjectHash bytes32 values. subjectHash is the escrow id.")
          return
        }
        if (reason.trim().length === 0) {
          onError("openDispute needs a reason string.")
          return
        }
        onPreview(previewOpenDispute(panel, id, subject, reason.trim()))
      }}
    >
      <h3>DisputePanel.openDispute</h3>
      <Field id="open-dispute-id" label="disputeId" value={disputeId} onChange={setDisputeId} />
      <Field
        id="open-subject"
        label="subjectHash"
        value={subjectHash}
        onChange={setSubjectHash}
        hint="Use the escrow id. The panel stores this as the subject."
      />
      <Field id="open-reason" label="reason" value={reason} onChange={setReason} />
      <button type="submit">Build openDispute calldata</button>
      <p className="hint">Target {panel}</p>
    </form>
  )
}

function DisputeForm({
  escrow,
  onPreview,
  onError,
}: {
  escrow: Address
  onPreview: (preview: CallPreview) => void
  onError: (message: string) => void
}) {
  const [escrowId, setEscrowId] = useState("")
  const [disputeId, setDisputeId] = useState("")
  return (
    <form
      onSubmit={(event) => {
        event.preventDefault()
        const id = parseBytes32(escrowId)
        const dispute = parseBytes32(disputeId)
        if (!id || !dispute) {
          onError("dispute() needs escrowId and disputeId bytes32 values.")
          return
        }
        onPreview(previewDispute(escrow, id, dispute))
      }}
    >
      <h3>Escrow.dispute</h3>
      <Field id="escrow-dispute-id" label="escrowId" value={escrowId} onChange={setEscrowId} />
      <Field id="escrow-dispute-panel-id" label="disputeId" value={disputeId} onChange={setDisputeId} />
      <button type="submit">Build dispute calldata</button>
    </form>
  )
}
