/** @jsxImportSource @opentui/solid */
import { execFile } from "node:child_process"
import { basename } from "node:path"
import { promisify } from "node:util"
import { createEffect, createMemo, createSignal, onCleanup, Show } from "solid-js"
import type { AssistantMessage } from "@opencode-ai/sdk/v2"
import type { TuiPluginApi, TuiPluginModule } from "@opencode-ai/plugin/tui"

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

function StatusLine(props: { api: TuiPluginApi; sessionID: string }) {
  const api = props.api
  const theme = () => api.theme.current
  const [git, setGit] = createSignal("")
  const last = createMemo(() =>
    api.state.session.messages(props.sessionID).findLast(
      (message): message is AssistantMessage =>
        message.role === "assistant" && message.tokens.output > 0,
    ),
  )
  const context = createMemo(() => {
    const message = last()
    if (!message) return undefined
    const tokens = message.tokens
    const used = tokens.input + tokens.output + tokens.reasoning + tokens.cache.read + tokens.cache.write
    const model = api.state.provider.find((provider) => provider.id === message.providerID)?.models[message.modelID]
    return model?.limit.context ? Math.round((used / model.limit.context) * 100) : undefined
  })
  const contextColor = () => {
    const percent = context()
    if (percent === undefined) return theme().textMuted
    if (percent < 30) return theme().success
    if (percent < 50) return "#fab387" // Catppuccin peach/orange
    return theme().error
  }
  const cache = createMemo(() => {
    const tokens = last()?.tokens
    if (!tokens) return undefined
    const input = tokens.input + tokens.cache.read + tokens.cache.write
    return input > 0 ? Math.round((tokens.cache.read / input) * 100) : undefined
  })
  const directory = createMemo(() =>
    api.state.session.get(props.sessionID)?.directory ?? last()?.path.cwd ?? api.state.path.directory,
  )

  createEffect(() => {
    const cwd = directory()
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
      <text fg={theme().textMuted} wrapMode="none">
        {"use   "}{bar(cache(), 10)} cache hit {cache() === undefined ? "—" : `${cache()}%`}
      </text>
      <Show when={git()}>
        <text fg={theme().textMuted} wrapMode="none">{"git   "}{git()}</text>
      </Show>
    </box>
  )
}

export default {
  id: "seth.statusline",
  async tui(api) {
    const sessionID = () => {
      const route = api.route.current
      return route.name === "session" && "params" in route && typeof route.params?.sessionID === "string"
        ? route.params.sessionID
        : undefined
    }
    api.slots.register({
      slots: {
        app_bottom() {
          return (
            <Show when={sessionID()} keyed>
              {(id) => <StatusLine api={api} sessionID={id} />}
            </Show>
          )
        },
      },
    })
  },
} satisfies TuiPluginModule
