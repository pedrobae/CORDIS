# GitHub Copilot Instructions for Cipher App
**IMPORTANT: UNLESS ASKED TO ACT DEFAULT TO A MENTOR ROLE, ASKING AND ANSWERING QUESTIONS AND GIVING ADVICE.**

## ✅ Language Configuration

**IMPORTANT: All developer communication must be in ENGLISH.**

### UI Text Guidelines (Using App Localization):
1. **All user-visible text must use localization keys** (via `context.l10n`)
2. **Localization files:** `cipher_app/lib/l10n/app_*.arb` (app_en.arb, app_pt.arb, etc.)
3. **Key naming pattern:** `context.l10n.featureName` (e.g., `context.l10n.analyzerTitle`, `context.l10n.noSectionsFound`)
4. **All code comments, variable names, and developer communication must be in English**

### Coding Conventions:
1. All code comments in English
2. Variable and function names in English
3. **User-visible text ONLY via localization keys** - never hardcode strings in widgets

## 🏗️ Architecture Overview

This Flutter app manages musical ciphers (chord charts) with layered offline-first architecture + optional cloud sync:

### Core Data Flow
```
SQLite DB ←→ Local Repository ←→ Provider (ChangeNotifier) ←→ UI
    ↕                    ↕
(seeds on first run)  Cloud Repo (optional downloads)
```

### Domain Model (Cipher → Version → Section)
- **Cipher**: Base entity with `title`, `author`, `musicKey`, `language`, `tags`, `firebaseId` (optional)
- **Version**: Arrangement of cipher with `versionName`, `songStructure` (List<String>), `sections` (Map<String, Section>), `transposedKey`
- **Section**: Content block in version with `contentCode`, `contentText`, `contentColor`, `contentType`
- **Playlist**: Collection of versions (many:many relationship via `playlist_version` table)

### Directory Structure
```
CORDIS/lib/
├── models/domain/          # Core domain (Cipher, Version, Section, Playlist)
├── models/dtos/            # Data transfer objects for serialization
├── repositories/           # Data access layer (Local + Cloud patterns)
├── providers/              # State management (16 ChangeNotifier providers)
├── screens/                # Full-screen UI components
├── widgets/                # Reusable UI components (cipher/editor, cipher/viewer)
├── helpers/                # Database
├── services/               # Firebase, Auth, Settings, Import/Parsing services
├── utils/                  # Color, String, Datetime helpers
├── l10n/                   # Localization files (app_*.arb)
└── routes/                 # AppRoutes navigation configuration
```

## 🗄️ Database Patterns

### Current Schema (v3)
```sql
cipher → version (1:many, different arrangements)
version → section (1:many, content blocks)
cipher ↔ tag (many:many via cipher_tags)
playlist → version (many:many via playlist_version)
```

### Database Initialization
```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const MyApp());
}
```

**Platform-Specific Behavior:**
- **Mobile (iOS/Android)**: Uses native sqflite (no setup needed)
- **Web**: -- Implemented later without local database, only firestore + cache

### Repository Layer Pattern
All repositories follow access pattern:
```dart
// Local repository (SQLite reads/writes)
final repository = LocalCipherRepository();
final cipher = await repository.getCipherById(id);

// Cloud repository (Firebase reads)
final cloudRepo = CloudCipherRepository();
final downloaded = await cloudRepo.downloadCipherData(firebaseId);
```

**Key Data Operations:**
- **getPruned()**: Metadata only (fast, for browsing)
- **getById()**: Full entity with relations loaded
- **insert/update/delete**: All go through local SQLite first

### Automatic Seeding
Database auto-seeds with sample data on first creation (in `CORDIS/lib/helpers/seed_data/`).

## 🔄 State Management Patterns

### Provider Ecosystem (16 Providers in main.dart)
```dart
// Core cipher/version management
ChangeNotifierProvider(create: (_) => CipherProvider()),      // Cipher CRUD + cloud sync
ChangeNotifierProvider(create: (_) => VersionProvider()),     // Version CRUD
ChangeNotifierProvider(create: (_) => SectionProvider()),     // Section CRUD

// Settings & UI state
ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
ChangeNotifierProvider(create: (_) => LayoutSettingsProvider()..loadSettings()),
ChangeNotifierProvider(create: (_) => NavigationProvider()),   // Bottom nav state
ChangeNotifierProvider(create: (_) => SelectionProvider()),    // Multi-select state

// Cloud & Auth
ChangeNotifierProvider(create: (_) => AuthProvider()),        // Firebase Auth
ChangeNotifierProvider(create: (_) => AdminProvider()),       // Admin operations

// Specialized domains
ChangeNotifierProvider(create: (_) => PlaylistProvider()),    // Playlist CRUD
ChangeNotifierProvider(create: (_) => UserProvider()..loadUsers()),
ChangeNotifierProvider(create: (_) => CollaboratorProvider()), // Share/permissions
ChangeNotifierProvider(create: (_) => ImportProvider()),      // PDF/file imports
ChangeNotifierProvider(create: (_) => ParserProvider()),      // Text parsing
ChangeNotifierProvider(create: (_) => TextSectionProvider()), // Text section editing
ChangeNotifierProvider(create: (_) => InfoProvider()),        // Info items (help content)
```

### Provider Usage Pattern
Each provider follows identical structure:
```dart
class CipherProvider extends ChangeNotifier {
  final LocalCipherRepository _repository = LocalCipherRepository();
  final CloudCipherRepository _cloudRepository = CloudCipherRepository();
  
  List<Cipher> _ciphers = [];
  bool _isLoading = false;
  String? _error;
  
  // Always call notifyListeners() after state changes
  Future<void> loadCiphers() async {
    _isLoading = true;
    try {
      _ciphers = await _repository.getAllCipher();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Critical Provider Patterns
1. **Cache State Awareness**: `CipherProvider._ciphers` serves multiple contexts (library + playlist)
   - Use `loadCiphers()` for library view (loads ALL ciphers once)
   - Use `getCachedCipher(id)` in playlists to avoid redundant loads
   - Call `versionProvider.clearVersions()` when switching between contexts

2. **Debouncing**: Form inputs use `Timer` for rapid updates
   - See `cipher_provider.dart` for `_loadTimer` pattern
   - Prevents excessive notifyListeners() calls

3. **Widget Loading Pattern**:
   ```dart
   class MyWidget extends StatefulWidget {
     @override
     void initState() {
       super.initState();
       // Pre-load with post-frame callback to avoid setState during build
       WidgetsBinding.instance.addPostFrameCallback((_) {
         final provider = context.read<MyProvider>();
         if (!provider.isDataLoaded(id)) {
           provider.loadData(id);
         }
       });
     }
   }
   ```

4. **Multi-Provider Access**:
   - Use `Consumer2`/`Consumer3` for widgets needing multiple providers
   - Separate concerns: CipherProvider + VersionProvider for editing
   - Keep providers independent (no direct provider-to-provider calls)

## 🎵 Cipher-Specific Patterns

### Section Color System
Predefined section types with default colors in `cipher_section_form.dart`:
```dart
const Map<String, Color> _defaultSectionColors = {
  'V1': Colors.blue,    // Verse 1
  'C': Colors.red,      // Chorus  
  'B': Colors.green,    // Bridge
  'I': Colors.purple,   // Intro
};
```

### Song Structure Format
Stored as `List<String>`: `["I", "V1", "C", "V2", "C", "B", "C", "F"]`
- Allows reuse of sections (multiple chorus occurrences)
- Order defines playback sequence
- Matches section keys in `Version.sections` map

### ChordPro Content Format
Sections contain ChordPro-formatted text for chord charts:
```
[Am]Amazing [F]grace, how [C]sweet the [G]sound
That [Am]saved a [F]wretch like [C]me
```

## 🔥 Firebase Integration Architecture

### On-Demand Download Strategy (Free Tier Optimized)
**Core Principle**: Only download full cipher data when user **actually views** the cipher, not when browsing or searching.

**Read Operation Optimization:**
- **Library Browsing**: Metadata only (title, author, tags) - 1 cached read per session
- **Cipher Viewing**: Full download on-demand - 1 read per unique cipher viewed
- **Result**: ~96% reduction in read operations vs. full sync approach

### Cloud Database Structure
```
firestore/
├── users/{userId}/
│   ├── profile: {name, email, preferences}  
│   ├── sharedPlaylists: {playlistId: permissions}
│   └── syncSessions: {sessionId: {timestamp, role}}
├── publicCiphers/{cipherId}/
│   ├── metadata: {title, author, musicKey, tags, downloadCount, lastUpdated}
│   └── fullData: {
│       versions: {versionId: {songStructure, sections: {...}}},
│       cipherData: {language, createdAt, contributors}
│     }
├── playlists/{playlistId}/
│   ├── metadata: {name, description, owner, public}
│   ├── items: [{type, contentId, order}]
│   ├── collaborators: {userId: permission}
│   └── presentation: {currentIndex, timestamp, presenter}
├── infoContent/{infoId}: {title, content, lastUpdated}
└── syncSessions/{sessionId}/
    ├── metadata: {playlistId, presenter, participants}
    └── state: {currentIndex, timestamp, isPlaying}
```

### Firebase Integration Patterns

**Critical Firebase Rules:**
1. **Offline-First Design**: SQLite remains primary data source, Firebase is download source
2. **On-Demand Downloads**: Only read full cipher data when viewing (not browsing)
3. **Repository Pattern Extension**: Extend existing repositories with cloud methods
4. **Permanent Local Storage**: Downloaded ciphers stored permanently in SQLite
5. **Authentication Required**: All cloud operations require Firebase Auth
6. **Real-time for Presentation Only**: Use Firestore listeners only for live presentation sync

**Firebase Services Structure:**
```dart
lib/services/
├── firebase_service.dart      // Core Firebase initialization
├── auth_service.dart          // Authentication wrapper
├── firestore_service.dart     // Firestore operations
└── (future) download_service.dart // On-demand cipher downloads
```

**Cloud Repository Extensions:**
```dart
// Extend existing repositories, don't replace them
class CloudCipherRepository {
  Future<List<CipherDto>> getPublicCipherMetadata(); // Browse without downloading
  Future<Cipher> downloadCipherData(String firebaseId); // Single read, full download
}
```

**Provider Integration:**
- `AuthProvider`: Manages Firebase Auth state
- `CipherProvider`: Handles both local and cloud cipher loading (with CloudCipherCache)
- Existing providers: Extended with cloud download methods without breaking local functionality

**Portuguese UI Extensions:**
- "Entrar" (Sign In), "Sair" (Sign Out)
- "Cifras da Nuvem" (Cloud Ciphers), "Baixar Cifra" (Download Cipher)
- "Baixando..." (Downloading...), "Cifra baixada!" (Cipher downloaded!)
- "Apresentação ao Vivo" (Live Presentation)

**Download Flow Integration:**
```dart
// In CipherViewer._loadData()
if (isFirebaseCipher(widget.cipherId)) {
  await cipherProvider.loadCipherFromFirebase(widget.firebaseCipherId);
} else {
  await cipherProvider.loadCipher(widget.cipherId); // Existing SQLite logic
}
```

## 🎨 UI Component Patterns

### Widget Organization
- `lib/widgets/cipher/editor/` - Complex form components for cipher editing
- `lib/widgets/cipher/viewer/` - Display components for cipher viewing
- Widgets are highly reusable and provider-agnostic when possible

### StatefulWidget Pattern for Provider Integration
**CRITICAL**: When creating widgets that need data from providers, follow this established pattern:

```dart
class MyWidget extends StatefulWidget {
  final int requiredId;
  final VoidCallback? onCallback;

  const MyWidget({
    super.key,
    required this.requiredId,
    this.onCallback,
  });

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Pre-load data with post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MyProvider>();
      if (!provider.isDataLoaded(widget.requiredId)) {
        provider.loadData(widget.requiredId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use for complex widgets that need to sync state when dependencies change
    // Example: When widget parameters change and need to reload provider data
    final provider = context.read<MyProvider>();
    if (provider.needsRefresh(widget.requiredId)) {
      provider.refreshData(widget.requiredId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyProvider>(
      builder: (context, provider, child) {
        final data = provider.getCachedData(widget.requiredId);
        
        if (data == null) {
          return const CircularProgressIndicator();
        }

        return MyActualWidget(
          data: data,
          onAction: () => widget.onCallback?.call(),
        );
      },
    );
  }
}
```

**Key Pattern Rules:**
1. **Always use StatefulWidget** for provider-dependent widgets that need pre-loading
2. **Pre-load in `initState`** with `WidgetsBinding.instance.addPostFrameCallback`
3. **Use `didChangeDependencies`** for complex widgets that need to react to dependency changes
4. **Access widget properties** as `widget.propertyName` in StatefulWidget context
5. **Use Consumer pattern** for reactive UI updates
6. **Handle loading states** with proper null checks and loading indicators
7. **Generate globally unique keys** for lists/reorderable widgets: `ValueKey('scope_${widget.id}_item_${itemId}_occurrence_$count')` for ReorderableListView (never use index), `ValueKey('scope_${widget.id}_item_$index')` for regular lists

### Color Utilities
Custom color handling in `lib/utils/color.dart`:
```dart
Color colorFromHex(String? hexColor)  // Handles null safely
String colorToHex(Color? color)       // Converts back for storage
```

### Navigation Pattern
- `AppRoutes` defines static routes and content routes
- Complex navigation (with parameters) uses `Navigator.push` directly
- `NavigationProvider` manages bottom navigation state


### Database Operations
- **Current schema version**: 3 (includes table renaming migration)
- **Seeded data**: 4 sample hymns on first creation (from `lib/helpers/seed_data/`)
- **Test reset**: Use `dbHelper.resetDatabase()` to get clean state with seeds
- **Desktop support**: Windows, Linux, macOS use FFI; iOS/Android use native sqflite

### Cloud Functions & Firestore
- **Cloud Functions**: `functions/index.js` contains backend logic
- **Firestore Rules**: `firestore.rules` defines security rules
- **Firebase Config**: `firebase.json` and `.firebaserc` configure projects
- **Local Testing**: `firebase emulators:start` for local Firebase emulation