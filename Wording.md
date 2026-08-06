# Wording — Technical Specification & Architecture Document

## 1. Overview
**Wording** is a local-first, serverless iOS application designed for language acquisition. It allows users to create custom languages, organize them into vocabulary dictionaries, and track word mastery without requiring an internet connection or backend infrastructure. All persistence is managed locally on-device using **SwiftData**.

---

## 2. Data Models & SwiftData Architecture

The application relies on three cascading models managed via SwiftData.

```text
+-------------------------------------------------------------+
|                         Language                            |
|-------------------------------------------------------------|
| - id: UUID                                                  |
| - title: String                                             |
| - vocabularies: [Vocabulary] (Cascade Delete)               |
+-------------------------------------------------------------+
                              | 1
                              |
                              | *
+-------------------------------------------------------------+
|                        Vocabulary                           |
|-------------------------------------------------------------|
| - id: UUID                                                  |
| - title: String                                             |
| - language: Language?                                       |
| - words: [WordItem] (Cascade Delete)                        |
|                                                             |
| + knownCount: Int (Computed)                                |
| + totalCount: Int (Computed)                                |
+-------------------------------------------------------------+
                              | 1
                              |
                              | *
+-------------------------------------------------------------+
|                         WordItem                            |
|-------------------------------------------------------------|
| - id: Int                                                   |
| - term: String                                              |
| - translation: String                                       |
| - learned: Bool                                             |
| - vocabulary: Vocabulary?                                   |
+-------------------------------------------------------------+
```

### SwiftData Model Implementations

```swift
import Foundation
import SwiftData

@Model
final class Language {
    var id: UUID
    var title: String
    
    @Relationship(deleteRule: .cascade, inverse: \Vocabulary.language)
    var vocabularies: [Vocabulary]
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.vocabularies = []
    }
}

@Model
final class Vocabulary {
    var id: UUID
    var title: String
    var language: Language?
    
    @Relationship(deleteRule: .cascade, inverse: \WordItem.vocabulary)
    var words: [WordItem]
    
    var knownCount: Int {
        words.filter { $0.learned }.count
    }
    
    var totalCount: Int {
        words.count
    }

    init(title: String, language: Language) {
        self.id = UUID()
        self.title = title
        self.language = language
        self.words = []
    }
}

@Model
final class WordItem {
    var id: Int
    var term: String
    var translation: String
    var learned: Bool
    var vocabulary: Vocabulary?

    init(id: Int, term: String, translation: String, learned: Bool = false) {
        self.id = id
        self.term = term
        self.translation = translation
        self.learned = learned
    }
}
```

---

## 3. Navigation & Screen Flow Map

```text
+-----------------------------------------------+
|                 Home Screen                   |
| - App Title ("Wording")                       |
| - List of Languages                           |
| - Add / Delete Language                       |
| - [Gear Icon] Settings (Bottom Left)          |
+-----------------------------------------------+
                       |
                       | (Tap Language)
                       v
+-----------------------------------------------+
|           Vocabulary List Screen              |
| - Back Button ("<")                           |
| - List of Vocabularies with progress badges   |
| - Add / Delete Vocabulary                     |
| - [Gear Icon] Settings (Bottom Left)          |
+-----------------------------------------------+
                       |
                       | (Tap Vocabulary)
                       v
+-----------------------------------------------+
|              Study / Word Screen              |
| - Display & Learn Words                       |
| - Toggle `learned` state                      |
+-----------------------------------------------+
```

---

## 4. Screen Specifications

### Screen 1: Home Screen (`HomeScreen`)

* **Header:** Title **"Wording"**.
* **Main Display:** List or grid of created `Language` cards.
* **Actions:**
  * **Create Language:** Prompts a creation alert or modal asking for a title string. Creates a `Language` instance and inserts it into the `modelContext`.
  * **Delete Language:** Swipe-to-delete or dedicated delete action. Triggers confirmation alert:
    > *"Are you sure you want to delete [Language Title]?"*  
    > **[ Cancel ]** | **[ Delete ]**
  * *Note:* Deleting a language automatically triggers SwiftData's `.cascade` deletion, removing all nested vocabularies and words.
* **Footer Navigation:** Fixed **Settings Icon** positioned on the bottom-left corner of the screen.

### Screen 2: Vocabulary List Screen (`VocabularyListScreen`)

* **Header:**
  * **Back Button:** Navigates back to the Home Screen.
  * Displays current language title.
* **Main Display:** List of `Vocabulary` dictionaries belonging to the active language.
  * **Progress Counter:** Each vocabulary row displays a badge showing `knownCount` / `totalCount` (calculated from `WordItem.learned == true`).
* **Actions:**
  * **Create Vocabulary:** Modal/Alert input to add a new named dictionary list.
  * **Delete Vocabulary:** Item deletion with confirmation alert:
    > *"Are you sure you want to delete this vocabulary list?"*  
    > **[ Cancel ]** | **[ Delete ]**
  * **Tap Vocabulary:** Navigates to the Study Screen for the selected dictionary.
* **Footer Navigation:** Fixed **Settings Icon** positioned on the bottom-left corner of the screen.

### Screen 3: Settings Overlay/Screen (`SettingsScreen`)

* **Access Point:** Persistent bottom-left gear icon available on both main screens.
* **Core Functions:**
  * **Data Backup (Export):** Encodes local SwiftData entities into portable `.json` files for device storage/sharing.
  * **Data Import:** Reads external `.json` files to populate SwiftData models locally.

---

## 5. JSON Import/Export Payload Schema

For backup and manual editing, the application maps local SwiftData models to the following JSON structure:

```json
{
  "language": "Spanish",
  "vocabularyTitle": "Food & Dining",
  "words": [
    {
      "id": 1,
      "term": "El queso",
      "translation": "Cheese",
      "learned": true
    },
    {
      "id": 2,
      "term": "La manzana",
      "translation": "Apple",
      "learned": false
    }
  ]
}
```