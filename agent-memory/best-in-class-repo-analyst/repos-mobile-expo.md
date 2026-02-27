# Mobile (Expo / React Native) Repositories

### infinitered/ignite
https://github.com/infinitered/ignite
Boilerplate / Reference architecture | 19.5K stars | Score: 94/100 | Last commit: Jan 2026 (v11.4.0)
Official: Referenced in Expo community resources
Oldest, most popular, most battle-tested RN/Expo boilerplate -- 9+ years active. Used by Infinite Red on real client projects. Since v9 ("Expresso"), full Expo integration with CNG workflow, Expo Router, MobX-State-Tree, TypeScript strict, generators.
**Caveats**: Opinionated (MobX-State-Tree). Large boilerplate. v11 dropped Expo Go support.

### obytes/react-native-template-obytes
https://github.com/obytes/react-native-template-obytes
Boilerplate / Starter kit | 4K stars | Score: 92/100 | Last commit: Jan 2026 (v9.0.0, Expo 53+)
Most modern and comprehensive Expo starter. Expo Router, TypeScript, NativeWind (TailwindCSS), React Query, Zustand, react-hook-form + Zod, MMKV, i18next, 10+ GitHub Actions workflows, unit (Jest/RTL) and E2E (Maestro) testing. Designed for AI-assisted development. Outstanding docs at starter.obytes.com.

### founded-labs/react-native-reusables
https://github.com/founded-labs/react-native-reusables
UI component library / Reference architecture | 7K+ stars | Score: 91/100 | Active
Definitive shadcn/ui port for React Native and Expo. Accessible, customizable UI components with NativeWind. CLI (@react-native-reusables/cli), copy-paste philosophy, light/dark themes. Full docs at reactnativereusables.com.
**Caveats**: Component library, not full app template. Transitioning to founded-labs org.

### t3-oss/create-t3-turbo
https://github.com/t3-oss/create-t3-turbo
Reference architecture / Monorepo template | 6K stars | Score: 90/100 | Recent (Expo SDK 54)
Official: Referenced in Expo monorepo docs
Official T3 Stack monorepo with Expo alongside Next.js. Turborepo with shared packages for API (tRPC v11), auth (Better Auth), DB (Drizzle + Supabase), UI (shadcn-ui), shared configs. Expo Router with NativeWind and typesafe tRPC.
**Caveats**: Expo app portion is thin. Best for teams building web + mobile simultaneously.

### byCedric/expo-monorepo-example
https://github.com/byCedric/expo-monorepo-example
Reference architecture / Monorepo example | 1.8K+ stars | Score: 85/100 | Active
Official: By Expo team member, referenced in Expo docs
Created by Cedric van Putten (senior dev at Expo). Canonical "vanilla" Expo monorepo -- intentionally minimal with no heavy frameworks. pnpm + Turborepo, Metro cache reuse, shared packages, efficient CI.
**Caveats**: Intentionally minimal -- not a full app template.

### roninoss/create-expo-stack
https://github.com/roninoss/create-expo-stack
CLI tool / Configurable starter generator | 2.5K stars | Score: 80/100 | Active (981 commits)
Interactive CLI for customized Expo projects. Choose TypeScript, Expo Router/React Navigation, NativeWind/Unistyles/Tamagui, Firebase/Supabase. Available at rn.new. Generates production-ready from latest SDK.
**Caveats**: Value in generated output, not as reference codebase. Quality varies by config.

### expo/examples
https://github.com/expo/examples
Official examples collection | 2K+ stars | Score: 76/100 | Continuously updated
Official: Official Expo repo, referenced in docs and CLI
Official Expo examples repo with 50+ focused examples. Each standalone and bootstrappable via npx create-expo --example <name>. Covers Expo Router, AI, auth, styling, API integrations.
**Caveats**: Small and focused -- not full architectures. Quality varies.
