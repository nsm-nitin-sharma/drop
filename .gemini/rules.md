# Antigravity Project Rules for Drop

## Core Directive (Always-On Rule)
Before executing any task or modifying code in this project, the AI agent MUST automatically adhere to the following workflow:

1. **Inspect & Understand First**:
   - Search for relevant existing files, models, services, controllers, and UI widgets before taking action.
   - Thoroughly inspect the existing codebase architecture and implementation patterns.
   - Never blindly create, modify, delete, or replace code without understanding existing context.

2. **Preserve & Minimize Changes**:
   - Preserve existing working functionality and contracts.
   - Reuse existing utilities, data models, theme structures, and components; strictly avoid duplicate implementations.
   - Make the minimum necessary code changes required to achieve the objective cleanly.

3. **Explain & Plan Before Significant Modifications**:
   - Before executing significant architectural changes or new feature implementations, summarize findings and present a clear implementation plan.

4. **Verify & Check for Errors**:
   - After completing code modifications, run static analysis and verification checks (`flutter analyze`, compilation/test checks) to ensure zero lint errors and zero regressions.

---

## Technical & Architectural Standards for Drop

### Architecture & Code Structure
- **MNC-Grade Clean Architecture** (Feature-First pattern):
  - `lib/core/`: Theme, network/Firebase providers, routing, errors, design system tokens, utility classes.
  - `lib/features/<feature_name>/`:
    - `data/`: Models, DTOs, data sources (Firestore, Firebase Storage, Local cache), repositories implementation.
    - `domain/`: Entities, repository interfaces, use cases.
    - `presentation/`: BLoCs/Cubits, states, pages, reusable widgets.
- **State Management**: BLoC / Cubit for predictable, scalable state transitions and strict separation of concerns.

### Database & Backend
- **Firebase Core Suite Only**:
  - Firebase Authentication (Email/Password, Google Sign-In, handle setup).
  - Cloud Firestore (Real-time database with optimized indexing, subcollections, transactions).
  - Firebase Storage (Media upload for high-res photos & compressed videos).
  - Firebase Cloud Messaging (FCM for real-time notifications).

### Design System & UI/UX
- **Monochrome Color Palette**: Black (`#000000`), White (`#FFFFFF`), Greyscale tones (`#121212`, `#1E1E1E`, `#2A2A2A`, `#E0E0E0`).
- **Modes**: Full support for Dark Mode, Light Mode, and System Theme.
- **Aesthetics & Motion**: Instagram-inspired sleek, minimal, addictive UI. Subtle micro-animations, Hero transitions, pull-to-refresh animations, smooth feed scrolling, custom like button heart pop animations.

### Security Standards ("Hard Security")
- Strict **Firestore Security Rules** (`firestore.rules`) ensuring users can only edit their own profile, post under their own UID, and read authorized content.
- Strict **Storage Security Rules** (`storage.rules`) validating mime-types and file size constraints.
- **Handle Uniqueness**: Unique `@username` registration enforced using Firestore atomic transactions to prevent duplicates or handle hijacking.

### Git & GitHub Workflow
- **Repository URL**: `https://github.com/nsm-nitin-sharma/drop.git`
- **Target Branch**: `AI` branch ONLY. (NEVER push directly to `main`).
- **Commit Cadence**: Commit and push progress after completing every crucial implementation phase.
