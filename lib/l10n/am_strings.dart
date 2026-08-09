/// English → Amharic translations for every user-facing string.
///
/// Keyed by the exact English source string used in the UI, so the app falls
/// back to English automatically for anything not yet translated. Grows as
/// screens are localized.
const Map<String, String> amStrings = <String, String>{
  // ── General / navigation ─────────────────────────────────────────────
  'Journal': 'መጽሔት',
  'Ledger': 'መዝገብ',
  'Giving': 'መስጠት',
  'Insights': 'ግንዛቤ',
  'Finance': 'ፋይናንስ',
  'Profile': 'መገለጫ',
  'Home': 'መነሻ',
  'Settings': 'ቅንብሮች',
  'Language': 'ቋንቋ',
  'Dark mode': 'ጨለማ ሁነታ',
  'Appearance': 'መልክ',
  'Notifications': 'ማሳወቂያዎች',
  'Search': 'ፈልግ',
  'All': 'ሁሉም',
  'None': 'የለም',
  'Add': 'ጨምር',
  'Save': 'አስቀምጥ',
  'Cancel': 'ሰርዝ',
  'Delete': 'አጥፋ',
  'Edit': 'አርትዕ',
  'Name': 'ስም',
  'Note': 'ማስታወሻ',
  'Notes': 'ማስታወሻዎች',
  'Amount': 'መጠን',
  'Date': 'ቀን',
  'Time': 'ሰዓት',
  'Type': 'ዓይነት',
  'Status': 'ሁኔታ',
  'Loading': 'በመጫን ላይ',
  'Error': 'ስህተት',
  'Close': 'ዝጋ',
  'Confirm': 'አረጋግጥ',
  'Back': 'ተመለስ',
  'Next': 'ቀጣይ',
  'Done': 'ተጠናቋል',
  'Continue': 'ቀጥል',
  'Skip': 'ዝለል',
  'View all': 'ሁሉንም ይመልከቱ',
  'See all': 'ሁሉንም ይመልከቱ',
  'Show': 'አሳይ',
  'Hide': 'ደብቅ',
  'Yes': 'አዎ',
  'No': 'አይደለም',
  'Retry': 'ደግመህ ሞክር',
  'Submit': 'አስገባ',
  'Send': 'ላክ',
  'Updated': 'ተሻሽሏል',
  'Optional': 'አማራጭ',
  'Required': 'የግድ ነው',

  // ── Finance concepts ──────────────────────────────────────────────────
  'Balance': 'ቀሪ ሂሳብ',
  'Total': 'ጠቅላላ',
  'Total Balance': 'ጠቅላላ ቀሪ ሂሳብ',
  'Income': 'ገቢ',
  'Expense': 'ወጪ',
  'Expenses': 'ወጪዎች',
  'Transfer': 'ዝውውር',
  'Transfers': 'ዝውውሮች',
  'Fees': 'ክፍያዎች',
  'Fee': 'ክፍያ',
  'Account': 'ሂሳብ',
  'Accounts': 'ሂሳቦች',
  'Savings': 'ቁጠባ',
  'Debt': 'ዕዳ',
  'Debts': 'ዕዳዎች',
  'Budget': 'በጀት',
  'Budgets': 'በጀቶች',
  'Tithe': 'አሥራት',
  'Currency': 'ገንዘብ (ምንዛሪ)',
  'Exchange Rate': 'የምንዛሪ ተመን',
  'Rate': 'ተመን',
  'Source': 'ምንጭ',
  'Destination': 'መድረሻ',
  'Recurring': 'ወቅታዊ',
  'History': 'ታሪክ',
  'Goal': 'ግብ',
  'Target': 'ኢላማ',

  // ── Period labels ─────────────────────────────────────────────────────
  'This Week': 'በዚህ ሳምንት',
  'This Month': 'በዚህ ወር',
  'Last 6 Months': 'ያለፉት 6 ወራት',
  'This Year': 'በዚህ ዓመት',
  'All Time': 'ሁሉም ጊዜ',
  'Week': 'ሳምንት',
  'Month': 'ወር',
  'Year': 'ዓመት',
  'Today': 'ዛሬ',
  'Yesterday': 'ትናንት',

  // ── Account types ─────────────────────────────────────────────────────
  'Bank': 'ባንክ',
  'Mobile Money': 'የሞባይል ገንዘብ',
  'Cash': 'ጥሬ ገንዘብ',
  'Savings Vault': 'የቁጠባ ሳጥን',

  // ── Transaction categories ────────────────────────────────────────────
  'Food': 'ምግብ',
  'Transport': 'መጓጓዣ',
  'Utilities': 'መገልገያዎች',
  'Entertainment': 'መዝናኛ',
  'Salary': 'ደሞዝ',
  'Freelance': 'ነፃ ሥራ',
  'Other': 'ሌላ',
  'Health': 'ጤና',
  'Education': 'ትምህርት',
  'Rent & Housing': 'ኪራይና መኖሪያ',
  'Clothing & Shopping': 'አልባሳትና ግብይት',
  'Business': 'ንግድ',
  'Taxes': 'ቀረጥ',
  'Insurance': 'መድን ዋስትና',
  'Subscriptions': 'ምዝገባዎች',
  // Mystique labels
  'Sustenance': 'ምግብ',
  'Carriage': 'መጓጓዣ',
  'The Hearth': 'መገልገያዎች',
  'Vices & Joy': 'መዝናኛ',
  'Grimoire Sales': 'ነፃ ሥራ',
  'Miscellany': 'ሌላ',
  'The Leech': 'ጤና',
  'The Scriptorium': 'ትምህርት',
  'The Hearthstone': 'ኪራይ',
  'The Wardrobe': 'አልባሳት',
  'The Merchant Guild': 'ንግድ',
  "The Crown's Due": 'ቀረጥ',
  'The Shield': 'መድን ዋስትና',
  'The Standing Dues': 'ምዝገባዎች',

  // ── Recurrence frequencies ────────────────────────────────────────────
  'Daily': 'በየቀኑ',
  'Weekly': 'በየሳምንቱ',
  'Monthly': 'በየወሩ',
  'Yearly': 'በየዓመቱ',

  // ── Lock screen ───────────────────────────────────────────────────────
  'Sealed': 'ተዘግቷል',
  'UNLOCK': 'ክፈት',
  'Not recognised — try again.': 'አልታወቀም — እንደገና ሞክር።',

  // ── Budget periods / misc labels ──────────────────────────────────────
  'Overall Spending': 'አጠቃላይ ወጪ',
  'Reversal': 'መቀልበስ',

  // ── Transfer categories ───────────────────────────────────────────────
  'Supermarket': 'ሱፐርማርኬት',
  'Bills & Utilities': 'ክፍያዎችና መገልገያዎች',
  'Family & Friends': 'ቤተሰብና ጓደኞች',
  'Fees & Charges': 'ክፍያዎችና ቀረጥ',

  // ── Drawer ────────────────────────────────────────────────────────────
  'FINANCIAL TOOLS': 'የፋይናንስ መሣሪያዎች',
  'Transfer Funds': 'ገንዘብ ማዛወር',
  'Debt Ledger': 'የዕዳ መዝገብ',
  'Add Account': 'ሂሳብ ጨምር',
  'Add an account': 'ሂሳብ ጨምር',
  'Budget Scrolls': 'የበጀት መዝገቦች',
  'My Profile': 'የእኔ መገለጫ',
  'Currency & rates': 'ገንዘብና ተመኖች',
  'Sign Out': 'ውጣ',
  'total balance': 'ጠቅላላ ቀሪ ሂሳብ',
  "Mystic Ledger  v1.1.0  ·  The Archivist's Grimoire":
      'Mystic Ledger  v1.1.0  ·  የመዝገብ አስተዳዳሪው ጥንታዊ መጽሐፍ',

  // ── Write errors ──────────────────────────────────────────────────────
  'That save was rejected. Try signing out and back in.':
      'ያ ማስቀመጫ ተቀባይነት አላገኘም። እባክህ ውጥተህ እንደገና ግባ።',
  'Your session expired. Please sign in again.':
      'ክፍለ ጊዜዎ አልቋል። እባክህ እንደገና ግባ።',
  'The archive is temporarily overloaded. Please try again in a moment.':
      'መዝገቡ በአሁኑ ጊዜ ሙሉ ነው። እባክህ ትንሽ ቆይተህ ሞክር።',
  'That record no longer exists.': 'ያ መዝገብ ከአሁን በኋላ የለም።',
  'Could not save': 'ማስቀመጥ አልተቻለም',
  'Please try again.': 'እባክህ እንደገና ሞክር።',
  'Something went wrong while saving. Please try again.':
      'ሲቀመጥ ስህተት ተፈጠረ። እባክህ እንደገና ሞክር።',

  // ── Lock screen ───────────────────────────────────────────────────────
  'Your ledger is locked. Unlock to read the records.':
      'መዝገብህ ተቆልፏል። ለማንበብ ክፈት።',
  'No fingerprint or PIN is enrolled on this device, so nothing can verify you. You can proceed without the lock.':
      'በዚህ መሣሪያ ላይ የጣት አሻራም ሆነ PIN የተመዘገበ የለም፣ ስለዚህ ሊያረጋግጥህ የሚችል ነገር የለም። ያለ መቆለፊያ መቀጠል ትችላለህ።',
  'Turn off the lock': 'መቆለፊያውን አጥፋ',

  // ── Splash ────────────────────────────────────────────────────────────
  'TRACK YOUR MONEY LIKE A STORY': 'ገንዘብህን እንደ ታሪክ ተከታተል',
  'Open the Journal': 'መጽሔቱን ክፈት',
  "The Archivist's Grimoire": 'የመዝገብ አስተዳዳሪው ጥንታዊ መጽሐፍ',

  // ── Auth ──────────────────────────────────────────────────────────────
  'Reset Password': 'የይለፍ ቃል መልስ',
  'Enter your email and we\'ll send a reset link.':
      'ኢሜይልህን አስገባ፣ የማስጀመሪያ ማስፈንገሪያ እንልክልሃለን።',
  'Reset link sent to': 'የማስጀመሪያ ማስፈንገሪያ ወደ',
  'Send Link': 'ማስፈንገሪያ ላክ',
  'Google sign-in failed. Please try again.':
      'የጉግል መግቢያ አልተሳካም። እባክህ እንደገና ሞክር።',
  'Begin Your\nLedger': 'መዝገብህን\nአስጀምር',
  'Welcome\nBack': 'እንኳን ደህና\nመጣህ',
  'CREATE YOUR ARCHIVIST ACCOUNT': 'የመዝገብ አስተዳዳሪ መለያህን ፍጠር',
  'SIGN IN TO YOUR GRIMOIRE': 'ወደ ጥንታዊ መጽሐፍህ ግባ',
  'FULL NAME': 'ሙሉ ስም',
  'Your archivist name': 'የመዝገብ አስተዳዳሪ ስምህ',
  'Enter your name': 'ስምህን አስገባ',
  'EMAIL': 'ኢሜይል',
  'Enter your email': 'ኢሜይልህን አስገባ',
  'Enter a valid email': 'ትክክለኛ ኢሜይል አስገባ',
  'PASSWORD': 'የይለፍ ቃል',
  'Enter your password': 'የይለፍ ቃልህን አስገባ',
  'At least 6 characters required': 'ቢያንስ 6 ፊደላት ያስፈልጋሉ',
  'Forgot password?': 'የይለፍ ቃል ረሳህ?',
  'Open the Ledger': 'መዝገቡን ክፈት',
  'Enter the Archive': 'ወደ መዝገብ ቤት ግባ',
  'Already have an account?': 'መለያ አለህ?',
  'No account yet?': 'መለያ የለህም?',
  'Sign In': 'ግባ',
  'Sign Up': 'ተመዝገብ',
  'OR': 'ወይም',
  'Continue with Google': 'በጉግል ቀጥል',

  // ── Onboarding ────────────────────────────────────────────────────────
  'Could not save. Check your connection and try again.':
      'ማስቀመጥ አልተቻለም። ግንኙነትህን አረጋግጠህ እንደገና ሞክር።',
  'First Steps': 'የመጀመሪያ ደረጃዎች',
  'SET UP YOUR LEDGER': 'መዝገብህን አዘጋጅ',
  'Base Currency': 'መሠረታዊ ገንዘብ',
  'Every total and report is shown in this currency. You can still hold money in others and convert between them.':
      'ሁሉም ድምርና ሪፖርቶች በዚህ ገንዘብ ይታያሉ። በሌሎች ገንዘቦች ማስቀመጥና መለወጥ ትችላለህ።',
  'Your First Account': 'የመጀመሪያ ሂሳብህ',
  'Where does your money live? A bank, mobile money, or cash in hand. You can add more vaults later.':
      'ገንዘብህ የት ይኖራል? ባንክ፣ የሞባይል ገንዘብ፣ ወይም ጥሬ ገንዘብ። በኋላ ተጨማሪ ሳጥኖችን መጨመር ትችላለህ።',
  'e.g. CBE Bank, Telebirr, Cash': 'ለምሳሌ CBE ባንክ፣ ቴሌብር፣ ጥሬ ገንዘብ',
  'You are ready': 'ዝግጁ ነህ',
  'Your ledger is open. Add entries, set a giving rate, and seal your first savings vault whenever you are ready.':
      'መዝገብህ ተከፍቷል። ግቤቶችን ጨምር፣ የመስጠት መጠን አዘጋጅ፣ እና ዝግጁ በሆንክ ጊዜ የመጀመሪያ ቁጠባህን ሳጥን ዝጋ።',
  'Auto-capture bank alerts': 'የባንክ ማሳወቂያዎችን አውቶማቲክ መያዝ',
  'On Android, Mystic Ledger can watch for Telebirr, CBE and Awash alerts in your messages and turn them into reviewable draft entries. You approve each one before it enters the ledger — nothing is recorded automatically.':
      'በአንድሮይድ ላይ፣ ሚስቲክ ሌጀር በመልዕክቶችህ ውስጥ የቴሌብር፣ CBE እና አዋሽ ማሳወቂያዎችን ተመልክቶ ወደ መገምገሚያ ረቂቅ ግቤቶች ይቀይራል። እያንዳንዱን ወደ መዝገቡ ከመግባቱ በፊት አንተ ታጸድቃለህ — ምንም በራሱ አይመዘገብም።',
  'Enable SMS capture': 'የSMS መያዝን አንቃ',
  'Permission is asked before anything is read.':
      'ማንኛውም ነገር ከመነበቡ በፊት ፈቃድ ይጠየቃል።',

  // ── Journal ───────────────────────────────────────────────────────────
  'A transaction waits to be recorded': 'የመመዝገቢያ ግቤት በመጠባበቅ ላይ ነው',
  'transactions wait to be recorded': 'ግቤቶች በመጠባበቅ ላይ ናቸው',
  'Captured from Telebirr, CBE & Awash — review before they enter the ledger':
      'ከቴሌብር፣ CBE እና አዋሽ ተይዘዋል — ወደ መዝገቡ ከመግባታቸው በፊት ገምግም',
  'CURRENT OBSERVATIONS': 'የአሁኑ ምልከታ',
  "Tap to hide or show every amount — each account's eye reveals it alone.":
      'ሁሉንም መጠኖች ለመደበቅ ወይም ለማሳየት ተጫን — የእያንዳንዱ ሂሳብ አይን ብቻውን ያሳየዋል።',
  'My Ledger': 'መዝገቤ',
  '"The ledger reflects what the season has given, and what it has taken."':
      '"መዝገቡ ወቅቱ የሰጠውንና የወሰደውን ያንጸባርቃል።"',
  'No vaults yet': 'እስካሁን ሳጥኖች የሉም',
  'Add the accounts you actually keep money in — a bank, mobile money, cash in hand — and the ledger fills itself from there.':
      'ገንዘብ የምታስቀምጥባቸውን ሂሳቦች ጨምር — ባንክ፣ የሞባይል ገንዘብ፣ ጥሬ ገንዘብ — መዝገቡ ከዚያ በራሱ ይሞላል።',
  'Recent Entries': 'የቅርብ ግቤቶች',
  'VIEW ARCHIVES': 'መዝገቦችን ይመልከቱ',
  'Your ledger awaits its first entry': 'መዝገብህ የመጀመሪያ ግቤቱን እየጠበቀ ነው',
  'ADD ENTRY': 'ግቤት ጨምር',

  // ── Ledger ────────────────────────────────────────────────────────────
  'All Entries': 'ሁሉም ግቤቶች',
  'ARCHIVE': 'መዝገብ ቤት',
  'ENTRIES': 'ግቤቶች',
  'Search the archive…': 'መዝገቡን ፈልግ…',
  'Load': 'ጫን',
  'more': 'ተጨማሪ',
  'remaining': 'የቀሩ',
  'No entries found': 'ምንም ግቤት አልተገኘም',
  'Delete entry?': 'ግቤቱን አጥፋ?',
  'Remove': 'አስወግድ',
  'fee': 'ክፍያ',

  // ── Giving ────────────────────────────────────────────────────────────
  'THIS WEEK': 'በዚህ ሳምንት',
  'THIS MONTH': 'በዚህ ወር',
  'ALL TIME': 'ሁሉም ጊዜ',
  'Select a giving period': 'የመስጠት ጊዜ ይምረጡ',
  'Apply': 'ተግብር',
  'You need an account before you can record giving.':
      'መስጠት ከመመዝገብህ በፊት ሂሳብ ያስፈልግሃል።',
  'ADD ACCOUNT': 'ሂሳብ ጨምር',
  'Recorded — your giving is now in the ledger.':
      'ተመዝግቧል — መስጠትህ አሁን በመዝገቡ ውስጥ ነው።',
  'Weekly (Sunday)': 'ሳምንታዊ (እሁድ)',
  'Custom': 'ብጁ',
  'Custom…': 'ብጁ…',
  'Sacred Giving': 'ቅዱስ መስጠት',
  'SESSION: CURRENT CYCLE': 'ክፍለ ጊዜ: የአሁኑ ዑደት',
  'HARVEST': 'መኸር',
  'Income recorded for this period — the basis for your tithe.':
      'ለዚህ ጊዜ የተመዘገበ ገቢ — ለአሥራትህ መሠረት ነው።',
  'Sunday Offering': 'የእሁድ ስጦታ',
  'OBLIGATION': 'ግዴታ',
  'ALREADY GIVEN': 'ቀድሞ የተሰጠ',
  'REMAINING': 'የቀረ',
  'No income recorded for this period yet.':
      'ለዚህ ጊዜ እስካሁን ምንም ገቢ አልተመዘገበም።',
  'Fulfilled for this period.': 'ለዚህ ጊዜ ተፈጽሟል።',
  'fulfilled': 'ተፈጽሟል',
  'still owed': 'አሁንም ዕዳ',
  'Nothing outstanding': 'ምንም የቀረ ነገር የለም',
  'Record Giving': 'መስጠትን መዝግብ',
  'HISTORY OF GIVING': 'የመስጠት ታሪክ',
  'No giving recorded for this period.':
      'ለዚህ ጊዜ ምንም መስጠት አልተመዘገበም።',
  'AMOUNT': 'መጠን',
  'FROM': 'ከ',
  'Available': 'ያለ',
  'Record': 'መዝግብ',
  'Giving rate': 'የመስጠት መጠን',
  'What share of your income do you set aside?':
      'ከገቢህ የትኛውን ድርሻ ትለያለህ?',
  'Record income to see what you have set aside for giving. Anything you give is logged as a Tithe entry in your ledger.':
      'ለመስጠት የለየኸውን ለማየት ገቢን መዝግብ። የምትሰጠው ማንኛውም ነገር በመዝገብህ ውስጥ እንደ አሥራት ግቤት ይመዘገባል።',
  'Nothing recorded yet for this period.':
      'ለዚህ ጊዜ እስካሁን ምንም አልተመዘገበም።',
  'is set aside as owed — tap Record Giving once you have given it.':
      'እንደ ዕዳ ተለይቶ ተቀምጧል — ከሰጠኸው በኋላ "መስጠትን መዝግብ" የሚለውን ተጫን።',
  'You have recorded': 'መዝግበሃል',
  'in giving for this period, meeting your commitment in full.':
      'ለዚህ ጊዜ በመስጠት፣ ቃልህን ሙሉ በሙሉ አሟልተሃል።',
  'You have given': 'ሰጥተሃል',
  'so far this period, with': 'በዚህ ጊዜ ውስጥ፣ ከ',
  'still outstanding.': 'ያልተፈጸመ ቀርቷል።',
  "Archivist's Note": 'የመዝገብ አስተዳዳሪ ማስታወሻ',

  // ── Finance hub ───────────────────────────────────────────────────────
  'FINANCIAL INSTRUMENTS': 'የፋይናንስ መሣሪያዎች',
  'Move between vaults': 'በሳጥኖች መካከል አንቀሳቅስ',
  'Vault deposits': 'የሳጥን ተቀማጭ',
  'Track obligations': 'ግዴታዎችን ክትትል',
  'Open new vault': 'አዲስ ሳጥን ክፈት',
  'Set spending limits': 'የወጪ ገደቦችን አዘጋጅ',
  'Transfer Record': 'የዝውውር መዝገብ',
  'History & reverse': 'ታሪክና መቀልበስ',
  'SAVINGS VAULTS': 'የቁጠባ ሳጥኖች',
  'SAVINGS VAULT': 'የቁጠባ ሳጥን',
  'Tap to open your first vault →': 'የመጀመሪያ ሳጥንህን ለመክፈት ተጫን →',
  'Tap to view deposits →': 'ተቀማጮችን ለማየት ተጫን →',
  'All Accounts': 'ሁሉም ሂሳቦች',
  'ADD': 'ጨምር',
  'No active accounts': 'ምንም ንቁ ሂሳቦች የሉም',
  'Add a vault to start recording against it.':
      'መመዝገብ ለመጀመር ሳጥን ጨምር።',
  'HIDDEN ACCOUNTS': 'የተደበቁ ሂሳቦች',
  'RESTORE': 'መልስ',
  'Debt Overview': 'የዕዳ አጠቃላይ እይታ',
  'VIEW ALL': 'ሁሉንም ይመልከቱ',
  'I OWE': 'እኔ ዕዳ',
  'OWED TO ME': 'ለእኔ ዕዳ',
  'pending': 'በመጠባበቅ ላይ',

  // ── Insights ───────────────────────────────────────────────────────────
  'Select a custom period': 'ብጁ ጊዜ ይምረጡ',
  'OBSERVATIONS': 'ምልከታዎች',
  '6 Months': '6 ወራት',
  'No entries yet.\nAdd income or an expense and your reports appear here.':
      'እስካሁን ምንም ግቤቶች የሉም።\nገቢ ወይም ወጪ ጨምርና ሪፖርቶችህ እዚህ ይታያሉ።',
  'INCOME': 'ገቢ',
  'EXPENSES': 'ወጪዎች',
  'NET': 'የተጣራ',
  'FEES PAID': 'የተከፈለ ክፍያ',
  'Income vs Expenses': 'ገቢ ከወጪ ጋር',
  'Nothing recorded in this period.':
      'በዚህ ጊዜ ምንም አልተመዘገበም።',
  'Running Balance': 'የሚንቀሳቀስ ቀሪ ሂሳብ',
  'Cumulative net position': 'ድምር የተጣራ አቋም',
  'At least two entries are needed to draw a trend.':
      'አዝማሚያ ለመሳል ቢያንስ ሁለት ግቤቶች ያስፈልጋሉ።',
  'Spending by Category': 'በምድብ የተከፋፈለ ወጪ',
  'Tap a slice to see the entries': 'ግቤቶቹን ለማየት ክፍሉን ተጫን',
  'No expenses in this period.': 'በዚህ ጊዜ ምንም ወጪ የለም።',
  'TOTAL': 'ጠቅላላ',
  'No entries.': 'ምንም ግቤቶች የሉም።',
  'Untitled': 'ርዕስ የሌለው',
  'Lost to Fees': 'በክፍያ የጠፋ',
  'Bank and service charges': 'የባንክና የአገልግሎት ክፍያዎች',
  'No fees recorded in this period.':
      'በዚህ ጊዜ ምንም ክፍያ አልተመዘገበም።',
  'of everything you spent went to charges rather than to what you bought.':
      'ያወጣኸው ገንዘብ ከምትገዛበት ይልቅ ወደ ክፍያዎች ሄዷል።',
  'Where Your Money Sits': 'ገንዘብህ የት ይገኛል',
  'Converted to': 'ወደ',
  'No account holds a balance yet.':
      'እስካሁን ምንም ሂሳብ ቀሪ ሂሳብ የለውም።',
  'HOLDINGS BY CURRENCY': 'በገንዘብ የተከፋፈሉ ንብረቶች',

  // ── Budget ────────────────────────────────────────────────────────────
  'SET SPENDING LIMITS PER PERIOD': 'በየጊዜው የወጪ ገደቦችን አዘጋጅ',
  'New Budget': 'አዲስ በጀት',
  'Budget History': 'የበጀት ታሪክ',
  'Budget history': 'የበጀት ታሪክ',
  'No budgets yet': 'እስካሁን ምንም በጀቶች የሉም',
  'Tap + New Budget to set a spending limit':
      'የወጪ ገደብ ለማዘጋጀት እሺ + አዲስ በጀት ተጫን',
  'Delete budget?': 'በጀቱን አጥፋ?',
  'SPENT': 'የወጣ',
  'BUDGET': 'በጀት',
  'Amend Budget Scroll': 'የበጀት መዝገብ አሻሽል',
  'New Budget Scroll': 'አዲስ የበጀት መዝገብ',
  'PERIOD': 'ጊዜ',
  'Overall': 'አጠቃላይ',
  'Update Budget': 'በጀት አዘምን',
  'Inscribe Budget': 'በጀት ጻፍ',

  // ── Profile ────────────────────────────────────────────────────────────
  'Delete Account?': 'መለያውን አጥፋ?',
  'This will permanently delete all your transactions, accounts, debts, budgets, and your profile. This cannot be undone.':
      'ይህ ሁሉንም ግቤቶችህን፣ ሂሳቦችህን፣ ዕዳዎችህን፣ በጀቶችህን እና መገለጫህን ለዘላለም ያጠፋል። ይህ መመለስ አይቻልም።',
  'Delete Everything': 'ሁሉንም አጥፋ',
  'MEMBER SINCE': 'አባል ከሆነበት ጊዜ',
  'Delete Account & All Data': 'መለያንና ሁሉንም ውሂብ አጥፋ',
  'DISPLAY NAME': 'የሚታይ ስም',
  'Your name': 'ስምህ',
  'Email cannot be changed here.': 'ኢሜይል እዚህ መቀየር አይቻልም።',
  'AUTO-CAPTURE': 'ራስ-ሰር መያዝ',
  'Telebirr, CBE & Awash alerts': 'የቴሌብር፣ CBE እና አዋሽ ማሳወቂያዎች',
  'Banks watched': 'የሚታዩ ባንኮች',
  'Incoming Telebirr, CBE and Awash alerts are read on this phone, parsed, and queued for your review — nothing is recorded without you, and raw messages never leave the device.':
      'የሚመጡ የቴሌብር፣ CBE እና አዋሽ ማሳወቂያዎች በዚህ ስልክ ይነበባሉ፣ ይተነተናሉ፣ እና ለክለሳህ ይሰለፋሉ — ያለአንተ ምንም አይመዘገብም፣ ጥሬ መልዕክቶችም ከመሣሪያው አይወጡም።',
  'SMS auto-capture is available on Android only.':
      'የSMS ራስ-ሰር መያዝ በአንድሮይድ ላይ ብቻ ይገኛል።',
  'SMS access granted — Telebirr, CBE and Awash alerts will be captured.':
      'የSMS ፈቃድ ተሰጥቷል — የቴሌብር፣ CBE እና አዋሽ ማሳወቂያዎች ይያዛሉ።',
  'SMS access was denied. Auto-capture needs it to read alerts.':
      'የSMS ፈቃድ ተከልክሏል። ማሳወቂያዎችን ለማንበብ ራስ-ሰር መያዝ ያስፈልገዋል።',
  'Could not scan the inbox — make sure SMS access is allowed.':
      'የገቢ መልዕክቶችን መቃኘት አልተቻለም — የSMS ፈቃድ መሰጠቱን አረጋግጥ።',
  'No bank transaction messages found in the inbox.':
      'በገቢ መልዕክቶች ውስጥ ምንም የባንክ ግብይት መልዕክት አልተገኘም።',
  'Allow SMS access': 'የSMS ፈቃድ ስጥ',
  'System permission to read bank alerts':
      'የባንክ ማሳወቂያዎችን ለማንበብ የስርዓት ፈቃድ',
  'Scan inbox for past messages': 'ለቀድሞ መልዕክቶች ገቢ መልዕክቶችን ቃኝ',
  'Pulls earlier bank alerts into the queue':
      'የቀደሙ የባንክ ማሳወቂያዎችን ወደ ወረፋው ያስገባል',
  'Review captured messages': 'የተያዙ መልዕክቶችን ገምግም',
  'Approve, edit, or dismiss before they are recorded':
      'ከመመዝገባቸው በፊት አጽድቅ፣ አርትዕ፣ ወይም ሰርዝ',
  'Export cancelled.': 'ወደ ውጭ መላክ ተሰርዟል።',
  'Could not share the export — try again.':
      'ወደ ውጭ መላክ አልተቻለም — እንደገና ሞክር።',
  'DATA TOOLS': 'የውሂብ መሣሪያዎች',
  'Recurring transactions': 'ወቅታዊ ግብይቶች',
  'Salary, rent, subscriptions — schedules that propose themselves':
      'ደሞዝ፣ ኪራይ፣ ምዝገባዎች — በራሳቸው የሚጠቁሙ ፕሮግራሞች',
  'Export to CSV': 'ወደ CSV ላክ',
  'Back up or share your records — transactions, transfers, debts, budgets':
      'መዝገቦችህን አስቀምጥ ወይም አጋራ — ግብይቶች፣ ዝውውሮች፣ ዕዳዎች፣ በጀቶች',
  'Biometric lock is available on Android and iOS only.':
      'ባዮሜትሪክ መቆለፊያ በአንድሮይድና በiOS ላይ ብቻ ይገኛል።',
  'No fingerprint or PIN is enrolled on this device, so the lock cannot verify you.':
      'በዚህ መሣሪያ ላይ የጣት አሻራም ሆነ PIN የተመዘገበ የለም፣ ስለዚህ መቆለፊያው ሊያረጋግጥህ አይችልም።',
  'APP LOCK': 'የመተግበሪያ መቆለፊያ',
  'Biometric / PIN gate': 'ባዮሜትሪክ / PIN መግቢያ',
  'Lock the ledger whenever the app leaves the screen. Your fingerprint or device PIN unlocks it.':
      'መተግበሪያው ከማያ ገጽ በወጣ ቁጥር መዝገቡን ይቆልፋል። የጣት አሻራህ ወይም የመሣሪያ PIN ይከፍተዋል።',
  'Available on Android and iOS devices.':
      'በአንድሮይድና በiOS መሣሪያዎች ላይ ይገኛል።',
  'APPEARANCE': 'መልክ',
  'Deep charcoal and ink — the grimoire after hours.':
      'ጥልቅ ጥቁር እና ቀለም — ጥንታዊ መጽሐፉ ከሥራ ሰዓት በኋላ።',
  'Alerts enabled — budget, debt, tithe and recurring reminders.':
      'ማሳወቂያዎች ተንቅነዋል — በጀት፣ ዕዳ፣ አሥራትና ወቅታዊ ማስታወሻዎች።',
  'Alerts disabled. Pending reminders were cancelled.':
      'ማሳወቂያዎች ጠፍተዋል። በመጠባበቅ ላይ ያሉ ማስታወሻዎች ተሰርዘዋል።',
  'Local reminders': 'የአካባቢ ማስታወሻዎች',
  'Budget limits at 80% and 100%, debt due dates, the tithe month-end check-in, and recurring-schedule prompts. All alerts are scheduled on this device.':
      'የበጀት ገደቦች በ80% እና 100%፣ የዕዳ መክፈያ ቀናት፣ የአሥራት የወር መጨረሻ ማስታወሻ፣ እና ወቅታዊ የፕሮግራም ማሳወቂያዎች። ሁሉም ማሳወቂያዎች በዚህ መሣሪያ ላይ ተይዘዋል።',
  'LANGUAGE': 'ቋንቋ',
  'The grimoire reads in English.': 'ጥንታዊ መጽሐፉ በእንግሊዝኛ ይነበባል።',

  // ── Captured ───────────────────────────────────────────────────────────
  'Captured': 'የተያዙ',
  'One message awaits your hand': 'አንድ መልዕክት እጅህን እየጠበቀ ነው',
  'Nothing captured yet': 'እስካሁን ምንም አልተያዘም',
  'Telebirr, CBE and Awash transaction alerts will appear here the moment they arrive. You can also scan your inbox to pull in older ones.':
      'የቴሌብር፣ CBE እና አዋሽ የግብይት ማሳወቂያዎች እንደደረሱ እዚህ ይታያሉ። ቀደምቶቹን ለማምጣት ገቢ መልዕክቶችህን መቃኘት ትችላለህ።',
  'Turn on auto-capture in Profile, then bank alerts will queue here for your review before they are recorded.':
      'በመገለጫ ውስጥ ራስ-ሰር መያዝን አንቃ፣ ከዚያ የባንክ ማሳወቂያዎች ከመመዝገባቸው በፊት ለክለሳህ እዚህ ይሰለፋሉ።',
  'SMS auto-capture is available on Android. On other platforms, entries are written by hand.':
      'የSMS ራስ-ሰር መያዝ በአንድሮይድ ላይ ይገኛል። በሌሎች መድረኮች ላይ ግቤቶች በእጅ ይጻፋሉ።',
  'See raw message': 'ጥሬ መልዕክቱን ተመልከት',
  'CONFIDENT': 'እርግጠኛ',
  'CHECK': 'አረጋግጥ',
  'UNCLEAR': 'ግልጽ ያልሆነ',
  'Awash Bank': 'አዋሽ ባንክ',
  'Received': 'ተቀብለዋል',
  'Sent / Paid': 'ተልኳል / ተከፍሏል',
  'Unclear': 'ግልጽ ያልሆነ',
  'Direction unclear': 'አቅጣጫ ግልጽ አይደለም',
  'Direction unclear — check the message before recording. A transfer between your own accounts is not income or expense.':
      'አቅጣጫ ግልጽ አይደለም — ከመመዝገብህ በፊት መልዕክቱን አረጋግጥ። በራስህ ሂሳቦች መካከል የሚደረግ ዝውውር ገቢም ወጪም አይደለም።',
  'amount unclear': 'መጠኑ ግልጽ አይደለም',
  'Showing': 'እያሳየ ነው',
  'Newest first': 'አዲሶቹ በመጀመሪያ',
  'Oldest first': 'የቆዩት በመጀመሪያ',
  'Largest amount': 'ትልቁ መጠን',
  'Smallest amount': 'ትንሹ መጠን',
  'Search the queue…': 'ወረፋውን ፈልግ…',
  'No matches — try a different search or filter.':
      'ምንም አልተገኘም — በሌላ ፍለጋ ወይም ማጣሪያ ሞክር።',

  // ── Recurring ──────────────────────────────────────────────────────────
  'NEW SCHEDULE': 'አዲስ ፕሮግራም',
  'Nothing repeats yet': 'እስካሁን ምንም ወቅታዊ የለም',
  'Salary, rent, subscriptions — set a schedule once and each occurrence lands in your review queue, ready to record.':
      'ደሞዝ፣ ኪራይ፣ ምዝገባዎች — አንድ ጊዜ ፕሮግራም አዘጋጅና እያንዳንዱ ክስተት ለመመዝገብ ተዘጋጅቶ በክለሳ ወረፋህ ውስጥ ይገባል።',
  'next due': 'ቀጣይ ቀን',
  'DUE': 'ቀኑ ደርሷል',
  'ACTIVE': 'ንቁ',
  'PAUSED': 'ቆሟል',
  'Amend Schedule': 'ፕሮግራም አሻሽል',
  'New Recurring': 'አዲስ ወቅታዊ',
  'e.g. Monthly salary': 'ለምሳሌ ወርሃዊ ደሞዝ',
  'TYPE': 'ዓይነት',
  'FREQUENCY': 'ድግግሞሽ',
  'NEXT DUE': 'ቀጣይ ቀን',
  'ACCOUNT': 'ሂሳብ',
  'Update Schedule': 'ፕሮግራም አዘምን',
  'Set Schedule': 'ፕሮግራም አዘጋጅ',
  'Remove this schedule': 'ይህን ፕሮግራም አስወግድ',
  'Remove schedule?': 'ፕሮግራሙን አስወግድ?',

  // ── Account detail ─────────────────────────────────────────────────────
  'Edit account': 'ሂሳብ አርትዕ',
  'This account is hidden from the home screen and pickers. Edit it above to restore it.':
      'ይህ ሂሳብ ከመነሻ ማያ ገጽና ከመራጮች ተደብቋል። ለመመለስ ከላይ አርትዕ።',
  'TRANSACTIONS': 'ግብይቶች',
  'No entries recorded against this vault.':
      'በዚህ ሳጥን ላይ ምንም ግቤት አልተመዘገበም።',
  'No money moved in or out of this vault.':
      'ወደዚህ ሳጥን ወይም ከዚህ ሳጥን ምንም ገንዘብ አልተንቀሳቀሰም።',

  // ── Transfer history ───────────────────────────────────────────────────
  'LOST TO TRANSFER FEES': 'በዝውውር ክፍያ የጠፋ',
  'across 1 transfer': 'በ1 ዝውውር ውስጥ',
  'across': 'በ',
  'REVERSED': 'ተመልሷል',
  'REVERSAL': 'መመለስ',
  'REVERSE': 'መልስ',
  'Reverse this transfer?': 'ይህን ዝውውር መልስ?',
  'A matching transfer in the opposite direction will be recorded. Both entries stay in your archive.':
      'በተቃራኒው አቅጣጫ ተጓዳኝ ዝውውር ይመዘገባል። ሁለቱም ግቤቶች በመዝገብህ ውስጥ ይቆያሉ።',
  'Leave off if the bank kept it.': 'ባንኩ ካስቀመጠው አትመልስ።',
  'Reverse': 'መልስ',
  'Transfer reversed — the ledger has been corrected.':
      'ዝውውሩ ተመልሷል — መዝገቡ ተስተካክሏል።',
  'No transfers recorded yet': 'እስካሁን ምንም ዝውውር አልተመዘገበም',
  'Unknown': 'ያልታወቀ',

  // ── Currency settings ──────────────────────────────────────────────────
  'BASE CURRENCY': 'መሠረታዊ ገንዘብ',
  'Your home total and all reports are shown in this currency.':
      'የቤት ድምርህና ሁሉም ሪፖርቶች በዚህ ገንዘብ ይታያሉ።',
  'EXCHANGE RATES': 'የምንዛሪ ተመኖች',
  'REFRESH RATES': 'ተመኖችን አድስ',
  'Could not reach the rate service — try again later.':
      'የተመን አገልግሎቱ ላይ መድረስ አልተቻለም — በኋላ ሞክር።',
  'No rate set — this currency is currently counted 1:1 in your total, which is almost certainly wrong.':
      'ምንም ተመን አልተዘጋጀም — ይህ ገንዘብ በአሁኑ ጊዜ በድምርህ 1:1 ይቆጠራል፣ ይህ ማለት በእርግጠኝነት ስህተት ነው።',

  // ── Auth errors ────────────────────────────────────────────────────────
  'That email is already registered.': 'ያ ኢሜይል ቀድሞ ተመዝግቧል።',
  'Please enter a valid email address.':
      'እባክህ ትክክለኛ የኢሜይል አድራሻ አስገባ።',
  'Password must be at least 6 characters.':
      'የይለፍ ቃል ቢያንስ 6 ፊደላት መሆን አለበት።',
  'No account found with that email.': 'በዚያ ኢሜይል ምንም መለያ አልተገኘም።',
  'Incorrect password. Please try again.':
      'የይለፍ ቃል ትክክል አይደለም። እባክህ እንደገና ሞክር።',
  'Too many attempts. Please wait a moment.':
      'ብዙ ሙከራዎች ተደርገዋል። እባክህ ትንሽ ቆይ።',
  'Please sign out and sign in again before deleting your account.':
      'መለያህን ከማጥፋትህ በፊት እባክህ ውጥተህ እንደገና ግባ።',
  'Authentication failed.': 'ማረጋገጥ አልተሳካም።',

  // ── Notifications ──────────────────────────────────────────────────────
  'Ledger alerts': 'የመዝገብ ማሳወቂያዎች',
  'Budget, debt, tithe and recurring reminders':
      'የበጀት፣ የዕዳ፣ የአሥራትና የወቅታዊ ማስታወሻዎች',
  'Budget nearly spent': 'በጀት ሊያልቅ ተቃርቧል',
  'Budget limit reached': 'የበጀት ገደብ ደርሷል',
  'Debt due tomorrow': 'ዕዳ ነገ ይደርሳል',
  'Debt due today': 'ዕዳ ዛሬ ይደርሳል',
  'Tithe check-in': 'የአሥራት ማስታወሻ',
  'The month ends today — record what you have set aside.':
      'ወሩ ዛሬ ያልቃል — ያስቀመጥከውን መዝግብ።',
  'This recurring entry is due — record it in the ledger.':
      'ይህ ወቅታዊ ግቤት ደርሷል — በመዝገብ ውስጥ መዝግብ።',

  // ── Add account ────────────────────────────────────────────────────────
  'OPEN NEW VAULT': 'አዲስ ሳጥን ክፈት',
  'New Account': 'አዲስ ሂሳብ',
  'ACCOUNT TYPE': 'የሂሳብ ዓይነት',
  'SAVINGS GOAL (OPTIONAL)': 'የቁጠባ ግብ (አማራጭ)',
  'e.g. 50000 for a laptop': 'ለምሳሌ 50000 ለላፕቶፕ',
  'Enter a valid goal': 'ትክክለኛ ግብ አስገባ',
  'ACCOUNT NAME': 'የሂሳብ ስም',
  'e.g. CBE, Awash Bank...': 'ለምሳሌ CBE፣ አዋሽ ባንክ...',
  'Enter an account name': 'የሂሳብ ስም አስገባ',
  'QUICK PICK': 'ፈጣን ምርጫ',
  'Open Vault': 'ሳጥን ክፈት',
  'Mobile': 'ሞባይል',

  // ── Debt ───────────────────────────────────────────────────────────────
  'No outstanding debts — your ledger is clean.':
      'ምንም ያልተከፈለ ዕዳ የለም — መዝገብህ ንጹህ ነው።',
  'No one owes you gold at the moment.':
      'በአሁኑ ጊዜ ማንም ወርቅ ዕዳ የለብህም።',
  'OUTSTANDING': 'ያልተከፈለ',
  'SETTLED': 'የተከፈለ',
  'TOTAL I OWE': 'ጠቅላላ ዕዳዬ',
  'TOTAL OWED TO ME': 'ለእኔ ያለብኝ ጠቅላላ',
  '1 item': '1 ነገር',
  'items': 'ነገሮች',
  'SETTLE': 'ክፈል',
  'ADD DEBT': 'ዕዳ ጨምር',
  'Amend Debt': 'ዕዳ አሻሽል',
  'Record Debt': 'ዕዳ መዝግብ',
  'PERSON / ORGANISATION': 'ሰው / ድርጅት',
  'Who is involved?': 'ማን ነው የተሳተፈው?',
  'Enter a name': 'ስም አስገባ',
  'DUE DATE (OPTIONAL)': 'የመክፈያ ቀን (አማራጭ)',
  'No deadline set': 'ምንም የመክፈያ ቀን አልተዘጋጀም',
  'Add context...': 'ማብራሪያ ጨምር...',
  'Update Record': 'መዝገብ አዘምን',
  'Record in Ledger': 'በመዝገብ ውስጥ መዝግብ',
  'Remove this debt': 'ይህን ዕዳ አስወግድ',
  'Delete debt?': 'ዕዳውን አጥፋ?',
  'This cannot be undone.': 'ይህ መመለስ አይቻልም።',

  // ── Transfer ──────────────────────────────────────────────────────────
  'Please select both accounts.': 'እባክህ ሁለቱንም ሂሳቦች ምረጥ።',
  'From and To accounts must be different.':
      'የሚዛወርበትና የሚዛወርበት ሂሳቦች የተለያዩ መሆን አለባቸው።',
  'Enter a valid amount greater than zero.':
      'ከዜሮ በላይ ትክክለኛ መጠን አስገባ።',
  'That account is no longer available.':
      'ያ ሂሳብ ከአሁን በኋላ የለም።',
  'Transfer recorded — gold moved between vaults.':
      'ዝውውሩ ተመዝግቧል — ወርቅ በሳጥኖች መካከል ተንቀሳቅሷል።',
  'Enter the rate you got:': 'ያገኘህበትን ተመን አስገባ:',
  'Insufficient balance. Available:': 'በቂ ቀሪ ሂሳብ የለም። ያለው:',
  'will arrive': 'ይደርሳል',
  'Converted from': 'የተቀየረ ከ',
  "currencies at today's rates.": 'በዛሬው ተመን ገንዘቦች።',
  'of': 'ከ',
  'saved': 'የተቀመጠ',
  'Deposit from': 'ተቀማጭ ከ',
  'Withdrawal to': 'ማውጣት ወደ',
  'Over by': 'የበለጠ በ',
  'used': 'የተጠቀመ',
  'Week of': 'ሳምንት የ',
  'budget for': 'በጀት ለ',
  'Over budget by': 'ከበጀት በላይ በ',
  'BUDGET AMOUNT': 'የበጀት መጠን',
  'OVERDUE': 'ጊዜው አልፏል',
  'Due': 'ቀኑ',
  'SCHEDULE': 'ፕሮግራም',
  'SCHEDULES': 'ፕሮግራሞች',
  'DUE ONES PROPOSE THEMSELVES ON RESUME':
      'የደረሱት በመተግበሪያው ሲከፈት በራሳቸው ይጠቁማሉ',
  'Received from': 'የተቀበለው ከ',
  'Sent to': 'የተላከው ወደ',
  'Review': 'ገምግም',
  'captured message(s)': 'የተያዙ መልዕክቶች',
  'captured message(s) queued for review.':
      'የተያዙ መልዕክቶች ለክለሳ ተሰልፈዋል።',
  'messages await your hand': 'መልዕክቶች እጅህን እየጠበቁ ናቸው',
  'transfer': 'ዝውውር',
  'transfers': 'ዝውውሮች',
  'Also refund the': 'እንዲሁም መልስ',
  'What one unit of each currency is worth in':
      'እያንዳንዱ ገንዘብ አንድ ክፍል የሚያወጣው በ',
  'Used to total accounts held in other currencies. Past transfers keep the rate they were recorded with.':
      'በሌሎች ገንዘቦች የተያዙ ሂሳቦችን ለማጠቃለል ይጠቅማል። ያለፉ ዝውውሮች የተመዘገቡበትን ተመን ይዘው ይቆያሉ።',
  'Every account is in': 'ሁሉም ሂሳቦች ያሉት በ',
  'so no rates are needed. Give an account a different currency and it will appear here.':
      'ስለዚህ ምንም ተመን አያስፈልግም። ለሂሳብ የተለየ ገንዘብ ስጥና እዚህ ይታያል።',
  'Rates refreshed for': 'ተመኖች ታድሰዋል ለ',
  'currencies.': 'ገንዘቦች።',
  'added to your vaults.': 'ወደ ሳጥኖችህ ተጨምሯል።',
  'You have used': 'ተጠቅመሃል',
  'of the': 'ከ',
  'limit.': 'ገደብ።',
  'Spending has met the': 'ወጪው የደረሰው',
  'limit for this period.': 'ለዚህ ጊዜ ያለውን ገደብ።',
  'comes due tomorrow.': 'ነገ ያበቃል።',
  'is due today.': 'ዛሬ ያበቃል።',
  'MOVE GOLD BETWEEN VAULTS': 'ወርቅ በሳጥኖች መካከል አንቀሳቅስ',
  'No vaults to move between': 'ለማንቀሳቀስ ሳጥኖች የሉም',
  'Only one vault so far': 'እስካሁን አንድ ሳጥን ብቻ ነው',
  'A transfer moves gold from one account to another, so it needs at least two. You have':
      'ዝውውር ወርቅን ከአንድ ሂሳብ ወደ ሌላ ያንቀሳቅሳል፣ ስለዚህ ቢያንስ ሁለት ያስፈልገዋል። አንተ',
  'Swap From and To': 'ከ እና ወደ ቀይር',
  'RATE AT THIS TIME': 'በዚህ ጊዜ ያለው ተመን',
  'Enter the rate to see what arrives':
      'ምን እንደሚደርስ ለማየት ተመኑን አስገባ',
  'Execute Transfer': 'ዝውውሩን አከናውን',
  'TRANSFER FEE / SERVICE CHARGE (OPTIONAL)':
      'የዝውውር ክፍያ / የአገልግሎት ክፍያ (አማራጭ)',
  '0.00  (bank/service fee)': '0.00 (የባንክ/የአገልግሎት ክፍያ)',
  'WHAT IS THIS FOR? (OPTIONAL)': 'ይህ ለምንድነው? (አማራጭ)',

  // ── Savings ────────────────────────────────────────────────────────────
  'No vault sealed yet': 'እስካሁን ምንም ሳጥን አልተዘጋም',
  'A savings vault is kept apart from your spending accounts, so what you set aside stays set aside. Open one to start.':
      'የቁጠባ ሳጥን ከወጪ ሂሳቦችህ ተለይቶ ይቀመጣል፣ ስለዚህ ያስቀመጥከው እንዳለ ይቆያል። ለመጀመር አንድ ክፈት።',
  'Open a vault': 'ሳጥን ክፈት',
  'DEPOSIT HISTORY': 'የተቀማጭ ታሪክ',
  'Total Saved': 'ጠቅላላ ቁጠባ',
  'Goal reached — the vault is sealed.': 'ግብ ተደርሷል — ሳጥኑ ተዘግቷል።',
  'No deposits yet': 'እስካሁን ምንም ተቀማጭ የለም',
  'Tap the button below to make your first deposit.':
      'የመጀመሪያ ተቀማጭህን ለማድረግ ከታች ያለውን አዝራር ተጫን።',
  'DEPOSIT': 'ተቀማጭ',
  'Deposit to Savings': 'ወደ ቁጠባ አስገባ',
  'A deposit has to come from somewhere. Add a spending account — bank, mobile money or cash — and it will show up here.':
      'ተቀማጭ ከአንድ ቦታ መምጣት አለበት። የወጪ ሂሳብ — ባንክ፣ የሞባይል ገንዘብ ወይም ጥሬ ገንዘብ — ጨምርና እዚህ ይታያል።',
  'ADD AN ACCOUNT': 'ሂሳብ ጨምር',
  'FROM ACCOUNT': 'ከሂሳብ',
  'TO VAULT': 'ወደ ሳጥን',
  'Seal in Vault': 'በሳጥን ውስጥ ዝጋ',
  '"Every coin sealed in the vault is a stone in the fortress of your future."':
      '"በሳጥኑ ውስጥ የተዘጋ እያንዳንዱ ሳንቲም ለወደፊትህ ምሽግ የሚሆን ድንጋይ ነው።"',

  // ── New entry ─────────────────────────────────────────────────────────
  'AMEND RECORD': 'መዝገብ አሻሽል',
  'NEW RECORD': 'አዲስ መዝገብ',
  'Revise Entry': 'ግቤት አሻሽል',
  'Write Entry': 'ግቤት ጻፍ',
  'Moon': 'ጨረቃ',
  'Nowhere to file this': 'ይህን የሚያስገባበት ቦታ የለም',
  'An entry has to be recorded against an account. Add the one this money moved through and come back.':
      'ግቤት በሂሳብ ላይ መመዝገብ አለበት። ይህ ገንዘብ ያለፈበትን ሂሳብ ጨምረህ ተመለስ።',
  'Enter an amount': 'መጠን አስገባ',
  'Enter a valid amount': 'ትክክለኛ መጠን አስገባ',
  'FEE / SERVICE CHARGE (OPTIONAL)': 'ክፍያ / የአገልግሎት ክፍያ (አማራጭ)',
  'DESCRIPTION': 'መግለጫ',
  'What was this entry for?': 'ይህ ግቤት ለምን ነበር?',
  'Enter a description': 'መግለጫ አስገባ',
  'CATEGORY': 'ምድብ',
  'removed': 'ተወግዷል',
  'This vault holds': 'ይህ ሳጥን የያዘው',
  'The amount will be recorded as': 'መጠኑ እንደ',
  'not converted from': 'ያልተቀየረ፣ ከ',
  'Save Changes': 'ለውጦችን አስቀምጥ',
  'Save Entry': 'ግቤት አስቀምጥ',
  'DISCARD CHANGES': 'ለውጦችን ሰርዝ',
  'DISCARD ENTRY': 'ግቤት ሰርዝ',
  'NOTE (OPTIONAL)': 'ማስታወሻ (አማራጭ)',
  'A brief annotation for the archive...':
      'ለመዝገቡ አጭር ማስታወሻ...',

  // ── Late additions (dark mode / language repaint pass) ────────────────
  'CANCEL': 'ሰርዝ',
  'BALANCE HIDDEN': 'ቀሪ ተደብቋል',
  'CURRENCY': 'ምንዛሬ',
  'GOAL': 'ግብ',
  'IGNORE': 'ተወው',
  'NAME': 'ስም',
  'NOTIFICATIONS': 'ማሳወቂያዎች',
  'RECORD': 'መዝግብ',
  'SETTINGS': 'ቅንብሮች',
  'TO': 'ወደ',
  'TRANSFERS': 'ዝውውሮች',
  'TOTAL BALANCE': 'ጠቅላላ ቀሪ ሒሳብ',
  'SAVINGS': 'ቁጠባ',
  'Edit Account': 'መለያ አርትዕ',
  'Edit Profile': 'መገለጫ አርትዕ',
  'Remove this account': 'ይህን መለያ አስወግድ',
  'Ref': 'ማጣቀሻ',
  'Target amount': 'የዒላማ መጠን',
  'How much are you saving up to? Leave blank to remove the goal.':
      'ምን ያህል ለመቆጠብ እያሰቡ ነው? ግቡን ለማስወገድ ባዶ ይተዉት።',
  'Remove the': 'አስወግድ',
  'This hides': 'ይህ ይደብቃል',
  'This account still holds': 'ይህ መለያ አሁንም ይይዛል',
  'Removing it hides that balance from your totals. Its history is preserved and you can restore it at any time.':
      'ማስወገድ ያንን ቀሪ ከጠቅላላዎ ይደብቃል። ታሪኩ ተጠብቆ ይቆያል እና በማንኛውም ጊዜ መመለስ ይችላሉ።',
  'from your home screen and pickers. Its history is preserved and you can restore it at any time.':
      'ከመነሻ ስክሪንዎ እና ከመራጮችዎ። ታሪኩ ተጠብቆ ይቆያል እና በማንኛውም ጊዜ መመለስ ይችላሉ።',
  'Remove the record of': 'የዚህን መዝገብ አስወግድ',
  'for': 'ለ',

  // ── Privacy & security batch ──────────────────────────────────────────
  'The pages are sealed.': 'ገጾቹ ተዘግተዋል።',
  'Auto-lock after inactivity': 'እንቅስቃሴ ሲያቅት በራስ-ሰር መቆለፍ',
  'Unlock Mystic Ledger to see your records.':
      'መዝገቦችዎን ለማየት ሚስቲክ ሌጀርን ይክፈቱ።',
  'Off': 'ጠፍቷል',

  // ── Cloud sync indicator ─────────────────────────────────────────────
  'Saving to Cloud…': 'ወደ ደመና በመቆጠብ ላይ…',
  'Synced to Cloud': 'ከደመና ጋር ተመሳስሏል',
  'Saving': 'በመቆጠብ ላይ',
  'Synced': 'ተመሳስሏል',
  'Offline': 'ከመስመር ውጭ',
  "You're offline — changes will sync when you're back online.":
      'ከመስመር ውጭ ነዎት — ለውጦችዎ ወደ ኔትወርክ ሲመለሱ ይመሳሰላሉ።',
  "You're offline — rates can't be refreshed right now.":
      'ከመስመር ውጭ ነዎት — በአሁኑ ጊዜ ዋጋዎችን ማደስ አይቻልም።',

  // ── CSV import ───────────────────────────────────────────────────────
  'Import from CSV': 'ከCSV አስመጣ',
  'Merge records from a spreadsheet exported by Mystic Ledger':
      'በMystic Ledger የተወጣ የተመን ሉህ መዝገቦችን ያዋህዱ',
  'Could not read that file.': 'ያንን ፋይል ማንበብ አልተቻለም።',
  'No importable rows found. Make sure the file was exported from Mystic Ledger.':
      'የሚገቡ ረድፎች አልተገኙም። ፋይሉ ከMystic Ledger የተወጣ መሆኑን ያረጋግጡ።',
  'Import records?': 'መዝገቦችን አስመጣ?',
  'records will be added to your ledger.':
      'መዝገቦች ወደ መዝገብዎ ይጨመራሉ።',
  'skipped — no matching account.': 'የተዘለሉ — ተዛማጅ አካውንት የለም።',
  'Import': 'አስመጣ',
  'entries imported.': 'ግቤቶች ገብተዋል።',
  'Import failed — try again.': 'ማስመጣት አልተሳካም — እንደገና ይሞክሩ።',

  // ── Encrypted backup (.mlbackup) ─────────────────────────────────────
  'BACKUP': 'መጠባበቂያ',
  'Back up now': 'አሁን መጠባበቂያ ያድርጉ',
  'Create an encrypted .mlbackup you can save anywhere':
      'በየትኛውም ቦታ ማስቀመጥ የሚችሉት የተመሰጠረ .mlbackup ይፍጠሩ',
  'Restore from backup': 'ከመጠባበቂያ መልስ',
  'Replace all data from an encrypted .mlbackup':
      'ከተመሰጠረ .mlbackup ሁሉንም ውሂብ ይተኩ',
  'Backup password': 'የመጠባበቂያ ይለፍ ቃል',
  'Choose a password to protect this backup. It is never stored anywhere.':
      'ይህን መጠባበቂያ ለመጠበቅ የይለፍ ቃል ይምረጡ። በየትኛውም ቦታ አይቀመጥም።',
  'Enter the password used when this backup was created.':
      'ይህ መጠባበቂያ በተፈጠረበት ጊዜ የተጠቀመውን የይለፍ ቃል ያስገቡ።',
  'Password': 'የይለፍ ቃል',
  'Confirm password': 'የይለፍ ቃል ያረጋግጡ',
  'Password must be at least 4 characters.':
      'የይለፍ ቃል ቢያንስ 4 ቁምፊዎች መሆን አለበት።',
  'Passwords do not match.': 'የይለፍ ቃሎች አይዛመዱም።',
  'Create backup': 'መጠባበቂያ ይፍጠሩ',
  'Unlock backup': 'መጠባበቂያውን ይክፈቱ',
  'Backup cancelled.': 'መጠባበቂያ ተሰርዟል።',
  'Could not create the backup — try again.':
      'መጠባበቂያ መፍጠር አልተቻለም — እንደገና ይሞክሩ።',
  'Could not decrypt the backup — is the password right?':
      'መጠባበቂያውን መክፈት አልተቻለም — የይለፍ ቃሉ ትክክል ነው?',
  'Restore backup?': 'ከመጠባበቂያ መልስ?',
  'records': 'መዝገቦች',
  'This replaces all current data with the backup contents.':
      'ይህ የአሁኑን ሁሉንም ውሂብ በመጠባበቂያው ይዘት ይተካል።',
  'Restore': 'መልስ',
  'records restored.': 'መዝገቦች ተመልሰዋል።',
  'Restore failed — try again.': 'መልሶ ማስገባት አልተሳካም — እንደገና ይሞክሩ።',

  // ── Tags & split transactions (missed in the earlier batch) ────────────
  'TAGS (OPTIONAL)': 'መለያዎች (አማራጭ)',
  'Add a tag…': 'መለያ ያክሉ…',
  'All tags': 'ሁሉም መለያዎች',
  'Split across categories': 'በምድቦች ተከፋፍሎ',
  'Add line': 'መስመር ያክሉ',
  'Lines total': 'የመስመሮች ድምር',
  'they must equal': 'እኩል መሆን አለባቸው',
  'Lines add up to the entry total.':
      'መስመሮቹ ወደ ግቤቱ ድምር ይደርሳሉ።',
  'Split amounts must add up to the entry total.':
      'የተከፋፈሉ መጠኖች ወደ ግቤቱ ድምር መድረስ አለባቸው።',
  'Enter an amount for every line.':
      'ለእያንዳንዱ መስመር መጠን ያስገቡ።',
};
