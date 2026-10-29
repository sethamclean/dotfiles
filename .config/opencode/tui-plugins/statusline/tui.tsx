/** @jsxImportSource @opentui/solid */
import { execFile } from "node:child_process"
import { basename } from "node:path"
import { promisify } from "node:util"
import { createEffect, createMemo, createSignal, onCleanup, Show } from "solid-js"
import type { SessionMessageAssistant } from "@opencode/client"
import { Plugin, usePlugin } from "@opencode/plugin/tui"

const exec = promisify(execFile)

function bar(percent: number | undefined, width: number) {
  if (percent === undefined) return `[${"?".repeat(width)}]`
  const filled = Math.floor(Math.max(0, Math.min(100, percent)) * width / 100)
  return `[${"#".repeat(filled)}${"-".repeat(width - filled)}]`
}

async function gitStatus(directory: string) {
  const run = async (...args: string[]) =>
    (await exec("git", ["-C", directory, ...args], {
      timeout: 1500,
      maxBuffer: 64 * 1024,
    })).stdout.trim()

  try {
    const [gitDir, commonDir, top] = (await run(
      "rev-parse", "--path-format=absolute", "--git-dir", "--git-common-dir", "--show-toplevel",
    )).split("\n")
    // symbolic-ref also works on a new branch before its first commit.
    const branch = await run("symbolic-ref", "--short", "-q", "HEAD")
      .catch(() => run("rev-parse", "--short", "HEAD"))
    return `${branch}${gitDir !== commonDir ? ` ⎇ wt:${basename(top)}` : ""}`
  } catch {
    return ""
  }
}

function StatusLine(props: { sessionID: string }) {
  const api = usePlugin()
  const location = createMemo(() =>
    api.data.session.get(props.sessionID)?.location ?? api.location ?? api.data.location.default(),
  )
  const [git, setGit] = createSignal("")
  const last = createMemo(() =>
    api.data.session.message.list(props.sessionID).findLast(
      (message): message is SessionMessageAssistant =>
        message.type === "assistant" && (message.tokens?.output ?? 0) > 0,
    ),
  )
  const context = createMemo(() => {
    const message = last()
    if (!message?.tokens) return undefined
    const tokens = message.tokens
    const used = tokens.input + tokens.output + tokens.reasoning + tokens.cache.read + tokens.cache.write
    const model = api.data.location.model.list(location())?.find((model) =>
      model.providerID === message.model.providerID && model.id === message.model.id,
    )
    return model?.limit.context ? Math.round((used / model.limit.context) * 100) : undefined
  })
  const contextColor = () => {
    const percent = context()
    if (percent === undefined) return api.theme.text.muted
    if (percent < 30) return api.theme.text.feedback.success.base
    if (percent < 50) return "#fab387" // Catppuccin peach/orange
    return api.theme.text.feedback.error.base
  }
  const cache = createMemo(() => {
    const tokens = last()?.tokens
    if (!tokens) return undefined
    const input = tokens.input + tokens.cache.read + tokens.cache.write
    return input > 0 ? Math.round((tokens.cache.read / input) * 100) : undefined
  })
  createEffect(() => {
    const cwd = location().directory
    let active = true
    let pending = false
    setGit("")
    const refresh = async () => {
      if (pending) return
      pending = true
      try {
        const value = cwd ? await gitStatus(cwd) : ""
        if (active) setGit(value)
      } finally {
        pending = false
      }
    }
    void refresh()
    const timer = setInterval(() => void refresh(), 5000)
    onCleanup(() => {
      active = false
      clearInterval(timer)
    })
  })

  return (
    <box flexDirection="column" paddingLeft={1} flexShrink={0}>
      <text fg={contextColor()} wrapMode="none">
        {"ctx   "}{bar(context(), 20)} {context() === undefined ? "—" : `${context()}%`}
      </text>
      <text fg={api.theme.text.muted} wrapMode="none">
        {"use   "}{bar(cache(), 10)} cache hit {cache() === undefined ? "—" : `${cache()}%`}
      </text>
      <Show when={git()}>
        <text fg={api.theme.text.muted} wrapMode="none">{"git   "}{git()}</text>
      </Show>
    </box>
  )
}

export default Plugin.define({
  id: "seth.statusline",
  setup(api) {
    return api.ui.slot({
      append: "session.composer.top",
      render: (props) => <StatusLine sessionID={props.sessionID} />,
    })
  },
})
