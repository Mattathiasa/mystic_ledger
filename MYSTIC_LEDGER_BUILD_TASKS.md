# Mystic Ledger — Complete Build Task List

> Paste each prompt exactly as written into a new Claude Code conversation.
> Complete tasks **in order** — later tasks depend on earlier ones.
> All tasks use Firebase (Firestore + Auth) as the backend.

---

## ✅ Already Done (Foundation Files)

These files are already created in `/lib/` — do NOT recreate them:

| File | Status |
|------|--------|
| `pubspec.yaml` | ✓ Updated (provider, google_fonts, intl added) |
| `lib/models/transaction.dart` | ✓ Complete |
| `lib/services/transaction_service.dart` | ✓ Complete (local/mock) |
| `lib/widgets/app_theme.dart` | ✓ Complete |

---

## 📋 Task Checklist

- [ ] Task 01 — Firebase Project Setup & Flutter Integration
- [ ] Task 02 — Firebase Auth Service + Login/Register Screens
- [ ] Task 03 — Firebase Firestore Transaction Service (replaces local service)
- [ ] Task 04 — `main.dart` — App Root, Theme, Provider, Auth Gate
- [ ] Task 05 — Splash Screen
- [ ] Task 06 — Main Scaffold & Bottom Navigation
- [ ] Task 07 — Shared Widgets (AppBar, AccountCard, TransactionTile)
- [ ] Task 08 — Journal Screen (Dashboard)
- [ ] Task 09 — Ledger Screen (All Entries)
- [ ] Task 10 — New Entry Screen (Add Transaction)
- [ ] Task 11 — Giving Screen (Sacred Tithe)
- [ ] Task 12 — Insights Screen (Monthly Observations + Chart)
- [ ] Task 13 — Firestore Security Rules
- [ ] Task 14 — Final Polish & Run Checklist

---

---

## TASK 01 — Firebase Project Setup & Flutter Integration

```
I am building a Flutter mobile app called Mystic Ledger — a personal finance tracker with a vintage journal aesthetic. I need you to:

1. Walk me through creating a Firebase project (console.firebase.google.com) and tell me exactly what settings to configure.

2. Then generate ALL the files needed to integrate Firebase into this Flutter project located at /Users/needsreset/Documents/Matty/mystic_ledger/

The existing pubspec.yaml already has these dependencies:
  provider: ^6.1.2
  google_fonts: ^6.2.1
  intl: ^0.19.0

Add the following Firebase dependencies to pubspec.yaml:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  google_sign_in: ^6.2.1

Generate:
A) The COMPLETE updated pubspec.yaml

B) Step-by-step Firebase console setup instructions:
   - Create project named "mystic-ledger"
   - Enable Authentication (Email/Password + Google)
   - Create Firestore database in production mode
   - Download and place google-services.json (Android) and GoogleService-Info.plist (iOS)

C) android/app/build.gradle changes needed for Firebase

D) android/build.gradle changes needed for Firebase

E) ios/Runner/AppDelegate.swift changes needed for Firebase (if any)

F) The updated lib/main.dart bootstrap that calls Firebase.initializeApp() before runApp

Make sure all Firebase package versions are compatible with Flutter 3.x and Dart SDK >=3.3.4 <4.0.0.
```

---

## TASK 02 — Firebase Auth Service + Login/Register Screens

```
I am building Mystic Ledger, a Flutter personal finance app with a vintage journal aesthetic ("The Archivist's Grimoire" design system).

The project is at /Users/needsreset/Documents/Matty/mystic_ledger/

DESIGN SYSTEM (use these exactly):
- Background: #FBFBE2 (parchment)
- Surface containers: #F5F5DC (low), #EAEAD1 (high), #E4E4CC (highest)
- Primary (dark gold): #735C00
- Primary container (bright gold): #D4AF37
- Secondary (forest green, income): #3C6929
- Tertiary (oxblood red, expense): #AD302F
- Text: #1B1D0E
- Outline: #7F7663
- Fonts: Epilogue (headlines, bold italic), Manrope (body), Space Grotesk (labels/uppercase)
- Aesthetic: vintage journal / hand-drawn / slightly rotated cards / parchment layers

The app already has:
- lib/widgets/app_theme.dart — exports MysticColors, buildMysticTheme(), headlineStyle(), bodyStyle(), labelStyle()
- lib/models/transaction.dart

Create these files:

1. lib/services/auth_service.dart
   - Wraps FirebaseAuth
   - Extends ChangeNotifier
   - Methods: signInWithEmail, signUpWithEmail, signInWithGoogle, signOut
   - Getters: currentUser (FirebaseAuth.instance.currentUser), isSignedIn
   - Stream: authStateChanges

2. lib/screens/auth/login_screen.dart
   - Full-screen parchment background
   - Big Epilogue italic title: "Mystic Ledger"
   - Subtitle label: "ENTER THE ARCHIVE"
   - Email + Password fields styled with bottom-border only (no box), outline color #7F7663
   - "Sign In" button — dark gold (#735C00) fill, white text, slightly rounded corners (radius 8)
   - "Sign in with Google" outlined button below
   - "New archivist? Create account" link at bottom
   - Tapping link navigates to RegisterScreen
   - On success navigate to MainScaffold (replace all routes)
   - Show SnackBar on error

3. lib/screens/auth/register_screen.dart
   - Same visual style as LoginScreen
   - Title: "Open a New Volume"
   - Fields: Display Name, Email, Password, Confirm Password
   - "Create Account" button
   - "Already have an account? Sign in" link
   - On success navigate to MainScaffold (replace all routes)

Both screens must use Consumer<AuthService> and show a CircularProgressIndicator while loading. Use the exact colors, fonts, and styles from the design system. No Material default colors.
```

---

## TASK 03 — Firebase Firestore Transaction Service

```
I am building Mystic Ledger, a Flutter personal finance app with a vintage journal aesthetic.

The project is at /Users/needsreset/Documents/Matty/mystic_ledger/

The existing lib/models/transaction.dart defines:

enum AccountType { telebirr, bank, cash }
enum TransactionType { income, expense }
enum TransactionCategory { food, transport, utilities, entertainment, tithe, salary, freelance, other }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final AccountType account;
  final TransactionCategory category;
  final DateTime date;
  final String? note;
  // + accountLabel, categoryLabel, categoryIcon getters
}

Create lib/services/transaction_service.dart — a Firestore-backed ChangeNotifier:

FIRESTORE STRUCTURE:
Collection path: users/{uid}/transactions/{transactionId}
Document fields:
  - id: string
  - title: string
  - amount: number
  - type: string ("income" | "expense")
  - account: string ("telebirr" | "bank" | "cash")
  - category: string ("food" | "transport" | "utilities" | "entertainment" | "tithe" | "salary" | "freelance" | "other")
  - date: timestamp
  - note: string? (nullable)
  - createdAt: timestamp (server timestamp)

REQUIRED:
1. TransactionService extends ChangeNotifier
2. Constructor takes uid: String
3. listens to Firestore snapshots in real-time (StreamSubscription)
4. dispose() cancels the subscription
5. Exposes:
   - List<Transaction> get transactions (sorted by date desc)
   - List<Transaction> get recentTransactions (first 5)
   - List<Transaction> filteredBy(TransactionType? type)
   - double get totalIncome
   - double get totalExpenses
   - double get balance
   - double get tithe (10% of totalIncome)
   - double accountBalance(AccountType account)
   - Map<TransactionCategory, double> get expensesByCategory
6. Future<void> addTransaction(Transaction t) — writes to Firestore
7. Future<void> deleteTransaction(String id) — deletes from Firestore
8. Static method: Transaction fromFirestore(DocumentSnapshot doc)
9. Static method: Map<String, dynamic> toFirestore(Transaction t)

Also include a static list of 11 mock transactions in a separate method _mockTransactions() that can be seeded to Firestore for new users (call this from the register flow).

The service must handle errors gracefully and not crash if Firestore is unavailable.
```

---

## TASK 04 — main.dart (App Root, Theme, Provider, Auth Gate)

```
I am building Mystic Ledger, a Flutter personal finance app with a vintage journal aesthetic.

Project: /Users/needsreset/Documents/Matty/mystic_ledger/

Files already created:
- lib/widgets/app_theme.dart (exports buildMysticTheme, MysticColors, headlineStyle, bodyStyle, labelStyle)
- lib/services/auth_service.dart (extends ChangeNotifier, has authStateChanges stream)
- lib/services/transaction_service.dart (extends ChangeNotifier, takes uid in constructor)
- lib/screens/auth/login_screen.dart
- lib/screens/splash_screen.dart
- lib/screens/main_scaffold.dart

Create the COMPLETE lib/main.dart that does:

1. Calls WidgetsFlutterBinding.ensureInitialized()
2. Calls Firebase.initializeApp() with DefaultFirebaseOptions.currentPlatform
3. Wraps the app in MultiProvider:
   - ChangeNotifierProvider<AuthService>
   - ChangeNotifierProxyProvider<AuthService, TransactionService>:
     * When user is signed in: create TransactionService(uid)
     * When user is null: create TransactionService with empty uid that returns empty data
4. MaterialApp with:
   - title: 'Mystic Ledger'
   - theme: buildMysticTheme()
   - home: _AuthGate widget (see below)
   - debugShowCheckedModeBanner: false

5. _AuthGate StatelessWidget:
   - Listens to AuthService
   - If loading: show full-screen parchment background with CircularProgressIndicator in gold color
   - If signed in: show MainScaffold
   - If not signed in: show LoginScreen

The app must handle the case where Firebase has not yet determined auth state (show loading).
No Navigator route strings needed — use direct widget returns from the auth gate.
```

---

## TASK 05 — Splash Screen

```
I am building Mystic Ledger, a Flutter personal finance app with a vintage journal aesthetic ("The Archivist's Grimoire").

Project: /Users/needsreset/Documents/Matty/mystic_ledger/
lib/widgets/app_theme.dart exports: MysticColors, headlineStyle(), bodyStyle(), labelStyle()

Create lib/screens/splash_screen.dart — a beautiful splash/onboarding screen.

DESIGN (from the stitch UI design file):
- Full parchment background (#FBFBE2)
- Subtle radial gold gradient at center: rgba(212,175,55,0.15) to transparent
- Central composition: a JOURNAL COVER rendered in Flutter widgets (NOT an image):
  * Dark brown cover (Color 0xFF292520), width 220, height 300, borderRadius 12
  * Left binding border: 14px wide, Color(0xFF1A1714)
  * Behind the cover: two offset parchment layers (translateX 6, translateY 6) for a stacked paper effect
  * Cover has a gold glow shadow: primaryContainer color at 40% opacity, blurRadius 32
  * Inside the cover: a circular border ring (radius 50, gold border 30% opacity)
  * Inside the ring: Icons.auto_awesome in gold (#D4AF37), size 52
  * Below the icon: two horizontal lines (widths 60 and 32) in gold 40% opacity
- The entire journal cover is slightly rotated: -1 degree
- Typography below the journal:
  * "Mystic Ledger" — Epilogue, 52px, weight 900, italic, dark brown
  * "TRACK YOUR MONEY LIKE A STORY" — Space Grotesk, 11px, letterSpacing 2.5, #7F7663
- CTA Button (56px below subtitle):
  * Full-width ElevatedButton
  * Label: "Open the Journal" with Icons.history_edu_outlined icon on right
  * Background: #735C00 (dark gold), text white
  * Slightly rounded (radius 8), gold outline border
  * Epilogue font, 18px, bold
  * On tap: Navigator.pushReplacement with a 600ms FadeTransition to MainScaffold
- Bottom meta row: "V 1.0.0" · "The Archivist's Grimoire" in Space Grotesk 10px #7F7663 60% opacity

The SplashScreen is shown ONLY on first launch (use shared_preferences to check a "launched_before" key). If already launched, navigate directly to the AuthGate (handled in main.dart, not here). This screen just navigates to MainScaffold on button tap.
```

---

## TASK 06 — Main Scaffold & Bottom Navigation

```
I am building Mystic Ledger, a Flutter personal finance app with a vintage journal aesthetic.

Project: /Users/needsreset/Documents/Matty/mystic_ledger/
lib/widgets/app_theme.dart exports: MysticColors, headlineStyle(), bodyStyle(), labelStyle()

Create lib/screens/main_scaffold.dart — the 4-tab shell:

DESIGN (from stitch HTML "my_ledger_dashboard"):
Bottom nav:
- Background: Color(0xFFF5F4E8) — warm parchment
- Top corners rounded: radius 28
- Top border: 1px outlineVariant at 50% opacity
- Box shadow: onSurface 6% opacity, blurRadius 40, offset (0,-8)
- 4 tabs: Journal, Ledger, Giving, Insights
- Each tab:
  * Icon + uppercase Space Grotesk 10px label below
  * Inactive: icon color Color(0xFF9E9B8A)
  * Active: background Color(0xFFD4AF37).withOpacity(0.25), icon/text color #735C00
  * Active tab: slight -1 degree rotation (animated with AnimatedContainer 200ms)
  * Icons: book_2 / edit_note / auto_awesome / analytics (filled when active)

Tab icons when ACTIVE (filled):
  - Journal: Icons.book_2
  - Ledger: Icons.edit_note
  - Giving: Icons.auto_awesome
  - Insights: Icons.analytics

Tab icons when INACTIVE:
  - Journal: Icons.book_2_outlined
  - Ledger: Icons.edit_note_outlined (use Icons.edit_note)
  - Giving: Icons.auto_awesome_outlined
  - Insights: Icons.analytics_outlined

SCAFFOLD:
- Use IndexedStack (preserves scroll position on tab switch)
- 4 screens: JournalScreen, LedgerScreen, GivingScreen, InsightsScreen
- import all 4 screens (they will exist as stubs if not yet built)
- SafeArea wraps the bottom nav content
- No default Flutter BottomNavigationBar — build a custom Container-based nav

Also create STUB files for any screen that doesn't exist yet:
- lib/screens/journal_screen.dart (Scaffold with "Journal" centered text)
- lib/screens/ledger_screen.dart (Scaffold with "Ledger" centered text)
- lib/screens/giving_screen.dart (Scaffold with "Giving" centered text)
- lib/screens/insights_screen.dart (Scaffold with "Insights" centered text)

These stubs will be replaced in later tasks.
```

---

## TASK 07 — Shared Widgets (MysticAppBar, AccountCard, TransactionTile)

```
I am building Mystic Ledger, a Flutter personal finance app with a vintage journal aesthetic ("The Archivist's Grimoire").

Project: /Users/needsreset/Documents/Matty/mystic_ledger/
lib/widgets/app_theme.dart exports: MysticColors, headlineStyle(), bodyStyle(), labelStyle()

lib/models/transaction.dart defines Transaction, TransactionType, AccountType, TransactionCategory.

Create these 3 reusable widget files:

────────────────────────────────────
1. lib/widgets/mystic_app_bar.dart
────────────────────────────────────
A PreferredSizeWidget (height 64) used as the appBar on all 4 tab screens.

Design:
- Background: Color(0xFFFDFCF0)
- Bottom border: 1.5px, outlineVariant 50% opacity
- Left: hamburger icon (Icons.menu) in gold (#735C00) — no action for now
- Center: "Mystic Ledger" — Epilogue, 24px, bold italic, letterSpacing -0.5
- Right: CircleAvatar radius 20, background surfaceContainerHighest, person_outline icon

Constructor: const MysticAppBar({super.key})

────────────────────────────────────
2. lib/widgets/account_card.dart
────────────────────────────────────
Displays a Telebirr / Bank / Cash balance card.

Constructor params:
  String label          // "Telebirr", "Bank Account", "Cash On Hand"
  String badge          // "Digital Vault", "Institutional", "Physical"
  double balance        // net balance for that account
  IconData icon         // account icon
  Color iconColor       // primary/secondary/tertiary
  Color bgColor         // surfaceContainerLow/High/Container
  double rotation       // slight tilt in radians (e.g. -0.009)
  bool wide             // if true, lays out horizontally (for Cash card spanning full width)

Design (from stitch my_ledger_dashboard HTML):
- Container with bgColor, borderRadius 16, border outlineVariant 15% opacity
- Subtle shadow: onSurface 4% opacity, blurRadius 12, offset (0,4)
- Transform.rotate with given angle
- Icon wrapped in a container: icon's color at 12% opacity background, borderRadius 10
- Badge: small label "DIGITAL VAULT" in Space Grotesk 9px, onSurface 5% opacity background
- Account name: Epilogue 16px bold (not italic)
- Balance: Manrope 20px bold, in iconColor
- If wide=true: Row layout [icon | spacer | label+balance column | badge]
- If wide=false: Column layout [Row(icon, badge) | spacer 20 | label | balance]

────────────────────────────────────
3. lib/widgets/transaction_tile.dart
────────────────────────────────────
A single row showing one transaction (used in Journal and Ledger screens).

Constructor: TransactionTile({required Transaction transaction})

Design (from stitch my_ledger_dashboard HTML entries):
- Container: bgColor surfaceContainerHighest, borderRadius 14, border outlineVariant 10% opacity
- Subtle shadow: onSurface 3%, blurRadius 8, offset (0,2)
- Left: 44x44 icon container (white 50% opacity bg, borderRadius 10)
  * Icon: transaction.categoryIcon
  * Icon color: secondary (green) for income, tertiary (red) for expense
- Middle column:
  * Title: transaction.title — Epilogue 16px bold (not italic)
  * Subtitle: "3:42 PM • SUSTENANCE" — Space Grotesk 9px uppercase, letterSpacing 0.8, onSurfaceVariant
  * Time logic: if <24h ago show time, if yesterday show "Yesterday", else show "Oct 14"
- Right column:
  * Amount: "+ETB 850.00" or "-ETB 42.50" — Manrope 15px bold, secondary/tertiary color
  * Account label: "TELEBIRR" — Space Grotesk 9px uppercase, onSurfaceVariant

Format amounts with NumberFormat('#,##0.00') from the intl package.
```

---

## TASK 08 — Journal Screen (Dashboard)

```
I am building Mystic Ledger, a Flutter personal finance app with a vintage journal aesthetic ("The Archivist's Grimoire").

Project: /Users/needsreset/Documents/Matty/mystic_ledger/

Existing files I have:
- lib/widgets/app_theme.dart — MysticColors, headlineStyle(), bodyStyle(), labelStyle()
- lib/widgets/mystic_app_bar.dart — MysticAppBar widget
- lib/widgets/account_card.dart — AccountCard widget
- lib/widgets/transaction_tile.dart — TransactionTile widget
- lib/services/transaction_service.dart — TransactionService (ChangeNotifier, Firestore-backed)
- lib/models/transaction.dart — Transaction, AccountType, TransactionType, TransactionCategory
- lib/screens/new_entry_screen.dart — NewEntryScreen (exists or will be a stub)

Replace lib/screens/journal_screen.dart with the FULL implementation:

DESIGN (from stitch "my_ledger_dashboard" HTML):

AppBar: use MysticAppBar()

BODY — SingleChildScrollView, padding (24, 32, 24, 120):

SECTION 1 — Balance Hero:
- "CURRENT OBSERVATIONS" — Space Grotesk 10px uppercase, letterSpacing 2.0, onSurfaceVariant 70% opacity
- "My Ledger" — Epilogue 48px, weight 900, italic
- Balance amount with a scribble-highlight effect:
  * Behind the text: a Container with primaryContainer at 30% opacity, height 20, slight -0.5deg rotation, organic border radius (topLeft 20, bottomRight 20, others 4)
  * "ETB " prefix — Manrope 28px bold, primary 60% opacity
  * Balance value — Manrope 42px bold, onSurface
  * Use NumberFormat('#,##0.00') 
- Below balance: italic quote in a left-bordered container (2px primaryContainer border):
  '"The ledger reflects a prosperous season. Gold flows through the Telebirr artery."'
  Manrope 13px italic, onSurfaceVariant

SECTION 2 — Account Cards (spacing 40 below hero):
- Row of two cards: Telebirr (surfaceContainerLow, rotation -0.009 rad) and Bank (surfaceContainerHigh, rotation +0.014 rad)
- Below that: Cash card full-width (surfaceContainer, rotation -0.005 rad, wide=true)
- Use AccountCard widget with these params:
  Telebirr: icon=Icons.account_balance_wallet_outlined, iconColor=primary
  Bank:     icon=Icons.account_balance_outlined, iconColor=secondary
  Cash:     icon=Icons.payments_outlined, iconColor=tertiary

SECTION 3 — Recent Entries (spacing 40 below cards):
- "Recent Entries" — Epilogue 28px bold italic
- "VIEW ARCHIVES" text button aligned right, Space Grotesk 10px, letterSpacing 1.5, primary color
- List of service.recentTransactions using TransactionTile, spaced 12px apart

FLOATING ACTION BUTTON (Positioned, bottom 24, right 24):
- NOT Flutter's default FAB
- Custom Container:
  * Background: MysticColors.primary
  * Padding: horizontal 20, vertical 16
  * Squircle shape: borderRadius.only(topLeft 24, topRight 16, bottomLeft 16, bottomRight 24)
  * Shadow: primary 40% opacity, blurRadius 20, offset (0,8)
  * Content: Row [ Icons.add (white, 22) | "ADD ENTRY" Space Grotesk 11px letterSpacing 1.5 white ]
- onTap: push NewEntryScreen with a SlideTransition (bottom to top, 400ms, easeOutCubic)

Wrap body in Stack so the FAB sits above the scroll content.
Use Consumer<TransactionService> for all data.
```

---

## TASK 09 — Ledger Screen (All Entries)

```
I am building Mystic Ledger, a Flutter personal finance app with a vintage journal aesthetic ("The Archivist's Grimoire").

Project: /Users/needsreset/Documents/Matty/mystic_ledger/

Existing files:
- lib/widgets/app_theme.dart — MysticColors, headlineStyle(), bodyStyle(), labelStyle()
- lib/widgets/mystic_app_bar.dart — MysticAppBar
- lib/services/transaction_service.dart — TransactionService (ChangeNotifier)
- lib/models/transaction.dart

Replace lib/screens/ledger_screen.dart with the FULL implementation:

DESIGN (from stitch "all_entries" HTML):

AppBar: MysticAppBar()

BODY — CustomScrollView with SliverToBoxAdapter sections:

SECTION 1 — Header (padding 24, top 32):
- "All Entries" — Epilogue 44px weight 900 italic
- "ARCHIVE: CURRENT CYCLE" — Space Grotesk 11px letterSpacing 2.0, onSurfaceVariant 70% opacity

SECTION 2 — Filter Tabs (below header, horizontal scroll):
Three filter chips: "All", "Income", "Expense"
- Active chip: MysticColors.primary background, white text, slight rotation applied (-1deg, +1deg, -0.5deg)
- Inactive chip: surfaceContainerHigh background, onSurfaceVariant text
- Each chip: Space Grotesk 11px uppercase letterSpacing 1.5, borderRadius 12, padding (20, 8)
- Animated with AnimatedContainer 200ms
- State: _filter = null (All), TransactionType.income, or TransactionType.expense

SECTION 3 — Journal/Ledger Container (margin horizontal 24):
- Container: bgColor surfaceContainerLow, borderRadius 24
- Shadow: onSurface 5% opacity, blurRadius 24, offset (0,8)
- Inside: Row with binding rings on left + entries list on right
- Binding rings: Column of 5 circles (w14, h14, margin vertical 20), border 2px outlineVariant 40% opacity

ENTRIES LIST (inside the journal container):
Each entry row (height 80):
- Bottom border: 1px outlineVariant 15% opacity (except last row)
- Left column:
  * Date: "OCT 24, 2023" — Space Grotesk 9px letterSpacing 0.8, onSurfaceVariant 60% opacity
  * Title: Manrope 15px bold
  * Category: transaction.categoryLabel — Space Grotesk 10px letterSpacing 0.5, secondary (income) or tertiary (expense) color
- Right: Amount — Manrope 16px weight 800, secondary/tertiary color (+ or - prefix)

EMPTY STATE (if no transactions):
- book_2_outlined icon 48px, outlineVariant color
- "No entries found" — Epilogue 16px italic, outline color

SECTION 4 — Load More button (centered, below container):
- OutlinedButton with Icons.expand_more icon
- Label: "Review Past Moons" — Epilogue 14px italic bold
- Style: primary color, outlineVariant border, borderRadius 24

Use Consumer<TransactionService>.
State managed with StatefulWidget for the filter selection.
```

---

## TASK 10 — New Entry Screen (Add Transaction)

```
I am building Mystic Ledger, a Flutter personal finance app with a vintage journal aesthetic ("The Archivist's Grimoire").

Project: /Users/needsreset/Documents/Matty/mystic_ledger/

Existing files:
- lib/widgets/app_theme.dart — MysticColors, headlineStyle(), bodyStyle(), labelStyle()
- lib/services/transaction_service.dart — TransactionService with addTransaction(Transaction)
- lib/models/transaction.dart — Transaction, AccountType, TransactionType, TransactionCategory

Create lib/screens/new_entry_screen.dart — a full-screen modal form:

DESIGN (from stitch "new_entry" HTML):

AppBar:
- Background Color(0xFFFDFCF0)
- Leading: back arrow (Icons.arrow_back, onSurface color)
- Title: "Mystic Ledger" italic Epilogue

BODY — SingleChildScrollView, max width 600, padding (24, 48, 24, 32):

HEADER:
- Row: left ["NEW RECORD" Space Grotesk 11px uppercase letterSpacing 2.0 outline | "Write Entry" Epilogue 36px bold italic -1deg rotation] | right ["Date of Observation" label + formatted date Epilogue 18px bold]
- Date shows today's date formatted as "15th Moon, 2024" (use day ordinal suffix)

FORM CARD — Container: surfaceContainerLow, borderRadius 32, padding 32, subtle shadow:

FIELD 1 — Amount:
- Label: "VALUE TRANSFERRED" Space Grotesk 10px uppercase letterSpacing 2.0 outline
- Big amount input:
  * Prefix: "ETB" — Epilogue 28px primary 40% opacity, positioned left
  * TextFormField: Epilogue 56px, no border box, only bottom border (1.5px outline 30%)
  * placeholder "0.00" in outlineVariant 30% opacity
  * keyboardType: TextInputType.numberWithOptions(decimal: true)

FIELD 2 — Type Selector (Nature of Flow):
- Label: "NATURE OF FLOW"
- Two toggle cards side by side:
  * "Expense" card: when selected → tertiary background, white text, -1deg rotation
  * "Income" card: when selected → secondary background, white text, +1deg rotation
  * When unselected: surfaceContainerHighest bg, outline text
  * Epilogue font, bold, 16px, padding 16, borderRadius 12

FIELD 3 — Category Chips (Sphere of Influence):
- Label: "SPHERE OF INFLUENCE"
- Wrap of chips: Food, Transport, Utilities, Entertainment, Tithe, Salary, Freelance, Other
- Selected chip: primaryContainer bg, onPrimaryContainer text, bold, slight -2deg rotation
- Unselected: border outlineVariant, outline text, borderRadius 24
- Font: Space Grotesk 12px

FIELD 4 — Account Selector (Vessel):
- Label: "VESSEL"
- DropdownButtonFormField:
  * Options: "Cash On Hand", "Telebirr Vault", "Bank Account"
  * Style: bottom border only (outline 30%), Manrope 18px
  * No box/outline border

FIELD 5 — Note (The Archivist's Note):
- Label: "THE ARCHIVIST'S NOTE"
- TextFormField multiline (3 rows):
  * Italic Manrope 16px
  * Placeholder: "Describe the circumstance..." outlineVariant 50% opacity
  * Bottom border only
  * Background: repeating horizontal lines every 32px (use boxDecoration with gradient)

SUBMIT BUTTON:
- Full width, padding vertical 20
- Background: MysticColors.primary, text: white
- Text: "Save Entry" — Epilogue 20px bold italic
- Shape: organic border-radius (255px 15px 225px 15px / 15px 225px 15px 255px as a custom border)
  Use: RoundedRectangleBorder with circular(8) and a side border in primaryFixed 50% opacity
- On tap: validate → create Transaction → context.read<TransactionService>().addTransaction() → Navigator.pop()

DISCARD button below:
- Text button "Discard Observation" with Icons.delete_sweep_outlined
- Space Grotesk 11px uppercase, outline 60% opacity

VALIDATION: amount must be > 0, title is required (use the description if empty, else generic).
Generate a unique ID with DateTime.now().millisecondsSinceEpoch.toString()
```

---

## TASK 11 — Giving Screen (Sacred Tithe)

```
I am building Mystic Ledger, a Flutter personal finance app with a vintage journal aesthetic ("The Archivist's Grimoire").

Project: /Users/needsreset/Documents/Matty/mystic_ledger/

Existing files:
- lib/widgets/app_theme.dart — MysticColors, headlineStyle(), bodyStyle(), labelStyle()
- lib/widgets/mystic_app_bar.dart — MysticAppBar
- lib/services/transaction_service.dart — provides totalIncome, tithe, transactions

Replace lib/screens/giving_screen.dart with the FULL implementation.

DESIGN (from stitch "sacred_giving" HTML):

AppBar: MysticAppBar()

BODY — SingleChildScrollView, padding (24, 32, 24, 100):

HEADER (centered):
- Icons.star_border, size 28, primary 60% opacity
- "Sacred Giving" — Epilogue 38px weight 900 italic, centered
- "SESSION: CURRENT CYCLE" — Space Grotesk 11px letterSpacing 2.0, onSurfaceVariant 60%

CARD 1 — Total Harvest (full width, -0.5deg rotation):
- Container: surfaceContainerLow, borderRadius 28, shadow
- Background decorative icon: Icons.auto_awesome, size 128, onSurface 5% opacity, top-right positioned
- "TOTAL HARVEST" — Space Grotesk 11px letterSpacing 2.0, secondary color
- Income amount — Epilogue 44px weight 900, with Icons.north_east (secondary) inline
- Use smart formatting: if >= 1000 show "X.XK ETB", else show full amount
- Italic quote below: "The ledger reflects a prosperous season..."

CARD 2 — Tithe Calculation (half width, left side):
- Container: surfaceContainerHighest, borderRadius 40, shadow, border outlineVariant 20% opacity
- Top row: [icon container (volunteer_activism filled, primary)] | ["10% TITHE" pill badge — primary bg, white text, Space Grotesk 10px]
- "CALCULATED PORTION" — Space Grotesk 10px uppercase, 60% opacity
- Tithe amount — Epilogue 36px bold, primary color (service.tithe)
- Divider: outlineVariant 15% opacity, height 1
- "Initiate Transfer" ElevatedButton:
  * Full width, primary bg, white text, Epilogue 16px bold, borderRadius 12
  * Shadow: primary 20% opacity
  * On tap: show a SnackBar "Tithe transfer recorded — Blessings upon the archive!"

CARD 3 — Commitment Status (half width, right side):
- Container: primary color background (dark gold), borderRadius 40, +0.5deg rotation
- Decorative bubble icon bottom-right, white 20% opacity
- Title "Commitment" Epilogue 18px bold italic white
- Label "COMPLETION STATUS" Space Grotesk 9px uppercase white 80%
- Progress circle (CustomPainter or just a Stack with CircleAvatar):
  * Outer circle: white 20% opacity stroke
  * Inner filled arc: calculate progress as (tithe_given / tithe_owed) — for MVP hardcode 100%
  * Center: Icons.check, white, size 28
- Status text: "Done" Epilogue 28px bold black white | subtitle italic white 80%
  (If tithe not yet given: show "Pending" instead)

CARD 4 — Archivist's Note (full width, below the 2 cards):
- Container: surfaceContainerLow, borderRadius 24, border outlineVariant 10%
- Row: Icons.history_edu, primaryContainer color, size 40 | Text paragraph
- "Archivist's Note" Epilogue 18px bold
- Note text: Manrope 14px onSurfaceVariant italic, "Historically, your sacred giving has increased the flow of secondary assets by 12% in subsequent moons..."
- Highlight "sacred giving" with a gold underline effect: Container height 2 primaryContainer 60% opacity

Use Consumer<TransactionService> for all monetary values.
```

---

## TASK 12 — Insights Screen (Monthly Observations + Chart)

```
I am building Mystic Ledger, a Flutter personal finance app with a vintage journal aesthetic ("The Archivist's Grimoire").

Project: /Users/needsreset/Documents/Matty/mystic_ledger/

Existing files:
- lib/widgets/app_theme.dart — MysticColors, headlineStyle(), bodyStyle(), labelStyle()
- lib/widgets/mystic_app_bar.dart — MysticAppBar
- lib/services/transaction_service.dart — expensesByCategory, totalIncome, totalExpenses, balance

Replace lib/screens/insights_screen.dart with the FULL implementation.

DESIGN (from stitch "monthly_observations" HTML):

AppBar: AppBar with title "Monthly Observations" (same style as MysticAppBar but different title)

BODY — parchment background, SingleChildScrollView, padding (24, 32, 24, 100):

SECTION 1 — This Month Summary:
- "THIS MONTH SUMMARY" — Space Grotesk 10px uppercase letterSpacing 2.0, onSurface 50% opacity
- 3-card grid in a Row:
  * Income card: surfaceContainerLow, rotate +0.3deg, "TOTAL HARVEST" label, amount in secondary (green)
  * Expenses card: surfaceContainerLow, rotate -0.5deg, "TOTAL FLOW" label, amount in tertiary (red)
  * Balance card: surfaceContainerHighest, rotate +0.2deg, "REMAINING ESSENCE" label, amount in primary (gold)
  Each card: padding 20, shadow, 1px outlineVariant divider at bottom
  Manrope 22px bold for amounts, Space Grotesk 10px for labels

SECTION 2 — Bar Chart (Where did my money go?):
- "Where did my money go?" — Epilogue 28px bold tracking-tight
- Custom bar chart widget (NO external chart library — build with Flutter Containers):
  Container: surfaceContainerLow, borderRadius 12, padding 24
  Build from service.expensesByCategory:
  - For each category with expenses > 0, render a vertical bar
  - Bar height is proportional to amount (max bar = 160px height)
  - Bar color: primary for highest category, primary 40% for others
  - Each bar has a hatching pattern overlay (use DecorationImage with a repeating linear gradient)
  - Amount label above each bar — Space Grotesk 10px onSurface 40%
  - Category label below — Space Grotesk 10px uppercase
  - Dashed horizontal grid lines (3 lines across, onSurface 10% opacity)
  - Bottom baseline: 1px border onSurface 20%
  - Show maximum 5 categories to avoid overflow

SECTION 3 — Top Expenditures List:
- "TOP EXPENDITURES" — Space Grotesk 10px uppercase letterSpacing 2.0, onSurface 50%
- List sorted by amount descending, showing top 5 expense categories
- Each row:
  * Icon container: 48x48, bg primary/onSurface 5% opacity, slight rotation ±2deg
  * Category name: Manrope 16px bold
  * Transaction count: "X TRANSACTIONS" Space Grotesk 10px onSurface 40%
  * Amount: Manrope 16px bold tertiary
  * Percentage: "XX% OF TOTAL FLOW" Space Grotesk 10px onSurface 40%
  * Row bg alternates: surfaceContainerLow / surface
  * On hover/tap: surfaceContainerHigh

FOOTER — Insight Quote:
- Icons.star, primary 40% opacity, rotated -15deg, left side decorative
- Italic Manrope 14px centered, onSurface 70%: "The stars suggest your gold flows most freely toward [top category]."
- Highlight [top category] with a gold underline (Container h1 primaryContainer 30% opacity)
- Icons.auto_awesome decorative right side

Use Consumer<TransactionService> for all data.
Compute transaction counts from service.transactions grouped by category.
```

---

## TASK 13 — Firestore Security Rules

```
I am building Mystic Ledger, a Flutter personal finance app backed by Firebase Firestore.

The Firestore data structure is:
  users/{uid}/transactions/{transactionId}
  
  Transaction document fields:
  - id: string
  - title: string
  - amount: number
  - type: string ("income" | "expense")
  - account: string ("telebirr" | "bank" | "cash")
  - category: string
  - date: timestamp
  - note: string (may be empty)
  - createdAt: timestamp

Write complete Firestore security rules (firestore.rules) that:

1. Deny all reads/writes by default
2. Allow a user to read and write ONLY their own transactions:
   - Read: allow if request.auth.uid == uid
   - Create: allow if:
     * request.auth.uid == uid
     * All required fields are present: id, title, amount, type, account, category, date, createdAt
     * amount is a number > 0
     * type is "income" or "expense"
     * account is "telebirr", "bank", or "cash"
     * title is a non-empty string with length <= 100
   - Update: allow if same ownership check + amount > 0 + title not empty
   - Delete: allow if request.auth.uid == uid

3. Deny access to any other collection paths

Also write firestore.indexes.json that creates a composite index for:
  Collection: transactions
  Fields: type (ascending) + date (descending)
  This supports the filteredBy() query with ordering.

Also write storage.rules (basic — no file uploads needed for MVP, just deny all).
```

---

## TASK 14 — Final Polish & Run Checklist

```
I am finishing Mystic Ledger, a Flutter personal finance app with vintage journal aesthetic.

Project: /Users/needsreset/Documents/Matty/mystic_ledger/

All screens and services are complete. Do the following final polish tasks:

1. KEYBOARD DISMISSAL
   Add a GestureDetector wrapping the root Scaffold body in all screens that calls
   FocusScope.of(context).unfocus() on tap — so the keyboard dismisses when tapping outside a field.

2. LOADING STATES
   In JournalScreen, LedgerScreen, GivingScreen, InsightsScreen:
   Show a centered CircularProgressIndicator in primaryContainer color while TransactionService
   is loading (add an isLoading bool getter to TransactionService that is true before first Firestore
   snapshot arrives).

3. ERROR STATES
   In TransactionService, add a String? error getter.
   In screens, if error is not null, show a centered Column:
   - Icons.warning_amber_outlined, tertiary color, size 48
   - "The archive is unavailable" Epilogue 18px italic
   - "Try again" TextButton in primary color that calls a retry() method

4. EMPTY STATES
   In JournalScreen (Recent Entries) when no transactions:
   - Icons.book_2_outlined, outlineVariant color, size 64
   - "Your ledger awaits its first entry" Epilogue 18px italic
   - "Write Your First Entry" ElevatedButton that opens NewEntryScreen

5. DELETE TRANSACTION
   In LedgerScreen, add swipe-to-delete on each row:
   Wrap each _LedgerRow in a Dismissible widget:
   - direction: DismissDirection.endToStart
   - background: Container with tertiary color, Icons.delete_outline white icon right-aligned
   - onDismissed: call service.deleteTransaction(transaction.id)
   - confirmDismiss: show AlertDialog "Erase this entry from the archive?" with Confirm/Cancel

6. TRANSACTION COUNT BADGE
   In MainScaffold bottom nav, show a small gold dot badge on the Ledger tab icon
   when a new transaction was added in the current session (use a simple bool flag).

7. PUBSPEC FLUTTER SECTION
   Ensure pubspec.yaml flutter section is correct and has no extra commented code.
   Clean it up to only have: uses-material-design: true

8. RUN CHECKLIST — verify these all work:
   □ flutter pub get — no dependency errors
   □ flutter analyze — no errors (warnings OK)
   □ App launches to splash screen on first run
   □ Login/Register screens work with Firebase Auth
   □ After login: MainScaffold shows with all 4 tabs
   □ Journal screen shows balance, 3 account cards, 5 recent entries
   □ FAB opens NewEntryScreen
   □ Saving a new transaction updates all screens in real time
   □ Ledger filter tabs (All/Income/Expense) work correctly
   □ Giving screen shows correct tithe = totalIncome × 10%
   □ Insights screen bar chart renders based on actual data
   □ Swipe to delete works in Ledger
   □ Sign out works (returns to LoginScreen)
   □ Firebase Firestore persists data across app restarts

Output: Any code fixes needed to make all checklist items pass.
```

---

## 📁 Final Project File Structure

```
mystic_ledger/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── transaction.dart          ✅ done
│   ├── services/
│   │   ├── transaction_service.dart  ✅ done (local) → Task 03 upgrades to Firestore
│   │   └── auth_service.dart         → Task 02
│   ├── widgets/
│   │   ├── app_theme.dart            ✅ done
│   │   ├── mystic_app_bar.dart       → Task 07
│   │   ├── account_card.dart         → Task 07
│   │   └── transaction_tile.dart     → Task 07
│   └── screens/
│       ├── splash_screen.dart        → Task 05
│       ├── main_scaffold.dart        → Task 06
│       ├── journal_screen.dart       → Task 08
│       ├── ledger_screen.dart        → Task 09
│       ├── new_entry_screen.dart     → Task 10
│       ├── giving_screen.dart        → Task 11
│       ├── insights_screen.dart      → Task 12
│       └── auth/
│           ├── login_screen.dart     → Task 02
│           └── register_screen.dart  → Task 02
├── firestore.rules                   → Task 13
├── firestore.indexes.json            → Task 13
├── pubspec.yaml                      ✅ done (Task 01 adds Firebase deps)
└── MYSTIC_LEDGER_BUILD_TASKS.md      ✅ this file
```

---

## 🔥 Firebase Collections Reference

```
Firestore:
  users/
    {uid}/
      transactions/
        {transactionId}: { id, title, amount, type, account, category, date, note, createdAt }

Auth:
  Email/Password
  Google Sign-In
```

---

## 🎨 Design System Quick Reference

| Token | Value |
|-------|-------|
| Background / Surface | `#FBFBE2` (parchment) |
| Surface Container Low | `#F5F5DC` |
| Surface Container | `#EFEFD7` |
| Surface Container High | `#EAEAD1` |
| Surface Container Highest | `#E4E4CC` |
| Primary (dark gold) | `#735C00` |
| Primary Container (bright gold) | `#D4AF37` |
| Secondary (income green) | `#3C6929` |
| Tertiary (expense red) | `#AD302F` |
| On Surface (text) | `#1B1D0E` |
| Outline | `#7F7663` |
| Outline Variant | `#D0C5AF` |
| Headline font | **Epilogue** (bold italic) |
| Body font | **Manrope** |
| Label font | **Space Grotesk** (uppercase) |
