---
name: mcp-apps
description: MCP Apps API reference, ShadCN theming, and testing guide. Use when the user mentions MCP App API, test MCP app, MCP app design, theme MCP app, ShadCN MCP, MCP CSS variables, MCP app display modes, debug MCP app, callServerTool, sendMessage, updateModelContext, or getUiCapability.
---

# MCP Apps -- API Reference, Theming & Testing

> **Creating or scaffolding an MCP App?** Use the `create-mcp-app` skill instead. It handles project setup, framework templates, build configuration, reference examples, and getting-started patterns.
>
> **Migrating from OpenAI Apps SDK?** Use the `migrate-oai-app` skill instead.
>
> **This skill** is the API reference and advanced guide. Use it when you need exact method signatures, CSP configuration, ShadCN theming, testing workflows, or advanced patterns for an existing MCP App.

SDK package: `@modelcontextprotocol/ext-apps` (spec `2026-01-26`)

---

# Server API Reference

## getUiCapability(clientCapabilities)

Check if the connected client supports MCP Apps. Essential for graceful fallback to text-only tools.

```ts
import { getUiCapability, RESOURCE_MIME_TYPE } from "@modelcontextprotocol/ext-apps/server";

server.server.oninitialized = () => {
  const caps = server.server.getClientCapabilities();
  const uiCap = getUiCapability(caps);

  if (uiCap?.mimeTypes?.includes(RESOURCE_MIME_TYPE)) {
    registerAppTool(server, "dashboard", { /* UI tool */ });
  } else {
    server.registerTool("dashboard", { description: "Get dashboard data" }, textHandler);
  }
};
```

## CSP (Content Security Policy)

Declare external domains in the resource's `_meta.ui.csp`. Undeclared domains are **silently blocked**.

```ts
_meta: {
  ui: {
    csp: {
      connectDomains: ["https://api.example.com"],      // fetch/XHR/WebSocket
      resourceDomains: ["https://cdn.example.com"],     // img/script/style/font
      frameDomains: ["https://embed.example.com"],      // nested iframes
      baseUriDomains: ["https://base.example.com"],     // document base
    },
  },
}
```

## Permissions

Request device capabilities on the resource:

```ts
_meta: {
  ui: {
    permissions: { camera: {}, microphone: {}, geolocation: {}, clipboardWrite: {} },
  },
}
```

## Resource Options

```ts
_meta: {
  ui: {
    domain: "myapp.example.com",  // Dedicated sandbox origin (for CORS/OAuth)
    prefersBorder: false,          // true=visible border, false=borderless, omitted=host decides
  },
}
```

---

# Client API Reference

## Request Methods (View -> Host)

### callServerTool -- Call MCP server tools from the UI

```ts
const result = await app.callServerTool({
  name: "update-quantity",
  arguments: { itemId: "abc", quantity: 3 },
});
// result: { content: [...], isError?: boolean, structuredContent?: {...} }
```

### sendMessage -- Send a message to the conversation

```ts
await app.sendMessage({
  role: "user",
  content: [{ type: "text", text: "User clicked 'Analyze trends'" }],
});
```

### updateModelContext -- Provide context to the model

Overwrites any previous context. Deferred until the next user message.

```ts
await app.updateModelContext({
  content: [{ type: "text", text: "Current selection: items A, B, C" }],
  structuredContent: { selectedItems: ["A", "B", "C"] },
});
```

### openLink -- Open a URL in the user's browser

```ts
await app.openLink({ url: "https://docs.example.com" });
```

### requestDisplayMode -- Switch display modes

```ts
const result = await app.requestDisplayMode({ mode: "fullscreen" });
// result.mode is the ACTUAL mode set (may differ if unsupported)
```

## Event Handlers (Host -> View)

| Handler | Params | When |
|---------|--------|------|
| `ontoolinput` | `{ arguments?: Record<string, unknown> }` | Complete tool arguments received |
| `ontoolinputpartial` | `{ arguments?: Record<string, unknown> }` | Streaming partial arguments (healed JSON) |
| `ontoolresult` | `CallToolResult` (`{ content, isError?, structuredContent? }`) | Tool execution finished |
| `ontoolcancelled` | `{ reason?: string }` | Tool execution cancelled |
| `onhostcontextchanged` | `McpUiHostContext` (partial) | Theme, display mode, or styles changed |
| `onteardown` | `(params, extra)` | Graceful shutdown before iframe removal |
| `oncalltool` | `(params, extra)` | Host calls a tool the App provides |

## Host Context (`McpUiHostContext`)

Available via `app.getHostContext()` after connection.

```ts
interface McpUiHostContext {
  toolInfo?: { id?: RequestId; tool: Tool };
  theme?: "light" | "dark";
  styles?: { variables?: McpUiStyles; css?: { fonts?: string } };
  displayMode?: "inline" | "fullscreen" | "pip";
  availableDisplayModes?: ("inline" | "fullscreen" | "pip")[];
  containerDimensions?: { height: number; width: number; maxHeight?: number; maxWidth?: number };
  locale?: string;        // BCP 47
  timeZone?: string;      // IANA
  platform?: "web" | "desktop" | "mobile";
  safeAreaInsets?: { top: number; right: number; bottom: number; left: number };
}
```

## Host Capabilities (`McpUiHostCapabilities`)

Available via `app.getHostCapabilities()` after connection.

```ts
interface McpUiHostCapabilities {
  openLinks?: {};
  serverTools?: { listChanged?: boolean };
  serverResources?: { listChanged?: boolean };
  logging?: {};
  sandbox?: { permissions?: McpUiResourcePermissions; csp?: McpUiResourceCsp };
  updateModelContext?: McpUiSupportedContentBlockModalities;
  message?: McpUiSupportedContentBlockModalities;
}
```

---

# React Hooks

## useDocumentTheme() -- Reactive theme

```tsx
const theme = useDocumentTheme();  // "light" | "dark"
```

Uses `MutationObserver` on `document.documentElement` watching `data-theme` attribute.

## useAutoResize(app, elementRef?) -- Manual resize

Only needed if you create `App` with `autoResize: false`.

---

# Standalone Style Utilities

Framework-agnostic functions (also re-exported from `/react`):

```ts
import {
  getDocumentTheme,          // () => "light" | "dark"
  applyDocumentTheme,        // (theme: "light" | "dark") => void
  applyHostStyleVariables,   // (styles: McpUiStyles, root?: HTMLElement) => void
  applyHostFonts,            // (fontCss: string) => void
} from "@modelcontextprotocol/ext-apps";
```

---

# Complete CSS Variable Reference

Always use fallback values. Host provides any subset of these.

## Colors

| Category | Variables |
|----------|-----------|
| Background | `--color-background-{primary,secondary,tertiary,inverse,ghost,info,danger,success,warning,disabled}` |
| Text | `--color-text-{primary,secondary,tertiary,inverse,ghost,info,danger,success,warning,disabled}` |
| Border | `--color-border-{primary,secondary,tertiary,inverse,ghost,info,danger,success,warning,disabled}` |
| Ring | `--color-ring-{primary,secondary,inverse,info,danger,success,warning}` |

## Typography

| Category | Variables |
|----------|-----------|
| Family | `--font-sans`, `--font-mono` |
| Weight | `--font-weight-{normal,medium,semibold,bold}` |
| Text size | `--font-text-{xs,sm,md,lg}-size` |
| Text line-height | `--font-text-{xs,sm,md,lg}-line-height` |
| Heading size | `--font-heading-{xs,sm,md,lg,xl,2xl,3xl}-size` |
| Heading line-height | `--font-heading-{xs,sm,md,lg,xl,2xl,3xl}-line-height` |

## Layout

| Category | Variables |
|----------|-----------|
| Border radius | `--border-radius-{xs,sm,md,lg,xl,full}` |
| Border width | `--border-width-regular` |
| Shadows | `--shadow-{hairline,sm,md,lg}` |

---

# ShadCN/ui Theming

ShadCN/ui uses CSS variables for theming, which maps naturally to MCP host variables. This gives automatic theme adaptation -- ShadCN components update when the host switches light/dark.

## ShadCN-to-MCP Variable Mapping

```css
:root {
  --background: var(--color-background-primary, #ffffff);
  --foreground: var(--color-text-primary, #0a0a0a);
  --card: var(--color-background-secondary, #ffffff);
  --card-foreground: var(--color-text-primary, #0a0a0a);
  --popover: var(--color-background-secondary, #ffffff);
  --popover-foreground: var(--color-text-primary, #0a0a0a);
  --primary: var(--color-background-inverse, #171717);
  --primary-foreground: var(--color-text-inverse, #fafafa);
  --secondary: var(--color-background-tertiary, #f5f5f5);
  --secondary-foreground: var(--color-text-primary, #171717);
  --muted: var(--color-background-tertiary, #f5f5f5);
  --muted-foreground: var(--color-text-secondary, #737373);
  --accent: var(--color-background-ghost, #f5f5f5);
  --accent-foreground: var(--color-text-primary, #171717);
  --destructive: var(--color-background-danger, #ef4444);
  --destructive-foreground: var(--color-text-inverse, #fafafa);
  --border: var(--color-border-primary, #e5e5e5);
  --input: var(--color-border-secondary, #e5e5e5);
  --ring: var(--color-ring-primary, #0a0a0a);
  --radius: var(--border-radius-md, 0.5rem);
}

[data-theme="dark"] {
  --background: var(--color-background-primary, #0a0a0a);
  --foreground: var(--color-text-primary, #fafafa);
  --card: var(--color-background-secondary, #0a0a0a);
  --card-foreground: var(--color-text-primary, #fafafa);
  --popover: var(--color-background-secondary, #0a0a0a);
  --popover-foreground: var(--color-text-primary, #fafafa);
  --primary: var(--color-background-inverse, #fafafa);
  --primary-foreground: var(--color-text-inverse, #171717);
  --secondary: var(--color-background-tertiary, #262626);
  --secondary-foreground: var(--color-text-primary, #fafafa);
  --muted: var(--color-background-tertiary, #262626);
  --muted-foreground: var(--color-text-secondary, #a3a3a3);
  --accent: var(--color-background-ghost, #262626);
  --accent-foreground: var(--color-text-primary, #fafafa);
  --destructive: var(--color-background-danger, #7f1d1d);
  --destructive-foreground: var(--color-text-inverse, #fafafa);
  --border: var(--color-border-primary, #262626);
  --input: var(--color-border-secondary, #262626);
  --ring: var(--color-ring-primary, #d4d4d4);
}
```

---

# Testing with Claude (Cloudflare Tunnel)

For testing with the actual Claude client (beyond `basic-host`, which is covered by `create-mcp-app`):

```bash
# If your server exposes an HTTP endpoint for development
npx cloudflared tunnel --url http://localhost:3000
```

Add to Claude Desktop config for local dev builds:

```json
{
  "mcpServers": {
    "my-app": {
      "command": "bash",
      "args": ["-c", "cd ~/code/my-app && npm run build >&2 && node dist/index.js --stdio"]
    }
  }
}
```

## sendLog Levels

`debug`, `info`, `notice`, `warning`, `error`, `critical`, `alert`, `emergency`

---

# Common Mistakes (beyond those in create-mcp-app)

The `create-mcp-app` skill covers: handlers before connect, single-file bundling, resource registration, resourceUri link, safe area, text fallback, hardcoded styles, streaming for large inputs.

**Additional pitfalls:**

1. **Calling updateModelContext too frequently**: Each call overwrites the previous context. Batch updates and only send when meaningful state changes occur.

2. **Ignoring requestDisplayMode response**: The host may not support the requested mode. Always check the returned `mode` value.

3. **Missing CSP declarations**: External fetch/image/script domains MUST be declared in the resource's `csp` config. Undeclared domains are silently blocked.

4. **Not handling teardown**: Always implement `onteardown` to clean up timers, WebSocket connections, and other resources before iframe removal.

5. **Forgetting CSS variable fallbacks**: Always use `var(--color-text-primary, #000)` -- hosts may not provide all variables.

6. **Not checking host capabilities**: Use `getUiCapability()` server-side and `getHostCapabilities()` client-side before calling methods the host may not support.
