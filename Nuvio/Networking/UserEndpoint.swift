//
//  UserEndpoint.swift
//  PiadinaExample
//
//  Created by Pietro Messineo on 5/25/25.
//

import Piadina
import Foundation

enum UserEndpoint {
    case createUser
    case getPlantDetails(message: String)
}

extension UserEndpoint: Endpoint {
    var path: String {
        switch self {
        case .createUser:
            return "/api/v1/users"
        case .getPlantDetails:
            return "/v1/chat/simpleChatCompletion"
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .createUser, .getPlantDetails:
            return .post
        }
    }
    
    var header: [String: String]? {
        switch self {
        case .createUser:
            return nil
        case .getPlantDetails:
            #if DEBUG
            return ["userid" : "user123", "User-Agent": "Nuvio"]
            #else
            return ["userid" : AppData.shared.userToken ?? "ERROR", "User-Agent": "Nuvio"]
            #endif
        }
    }
    
    var body: [String: Any]? {
        switch self {
        case .createUser:
            return [
                "userId": AppData.shared.userToken ?? "",
                "email": AppData.shared.email ?? "unknown"
            ]
        case .getPlantDetails(let imgUrl):
            return [
                "model": "gpt-4.1-nano",
                "messages":  [
                    [
                        "role": "system",
                        "content": """
                        You are Nuvio, an iOS App used from students to learn or speedup their learning path.
                        """
                    ],
                    [
                        "role": "user",
                        "content": imgUrl
                    ]
                ]
            ]
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .createUser, .getPlantDetails:
            return nil
        }
    }
}

private func getLocalizedPromptContent() -> String {
    let locale = Locale.current
    let languageCode = locale.language.languageCode?.identifier ?? "en"
    
    switch languageCode {
    case "fr":
        return """
        TÂCHE  
        1. Identifiez la plante dans l'image aussi précisément que possible.  
        2. Remplissez TOUS les champs ci-dessous en suivant EXACTEMENT le format spécifié.
        3. Retournez **uniquement** du JSON valide (pas de markdown, commentaires ou clés supplémentaires).  
        4. N'ajoutez pas de texte explicatif en dehors du JSON.
        5. Suivez EXACTEMENT les valeurs d'énumération spécifiées.
        6. N'utilisez jamais le caractère 0xa
        7. IMPORTANT : Répondez en français pour toutes les valeurs textuelles dans le JSON.
        8. Make sure that pre-defined value like "Toxic" | "Non-toxic" | "Unknown" or "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown" etc, will still be returned in English.
        
        SCHÉMA JSON (ordre et valeurs exacts des clés)  
        {
        "name": "string",
        "family": "string",
        "poisonous": {
            "isPoisonous": boolean | null,
            "details": "string | null"
        },
        "petToxicity": {
            "cats": "Toxic" | "Non-toxic" | "Unknown",
            "dogs": "Toxic" | "Non-toxic" | "Unknown",
            "other": "string | null"
        },
        "careDifficulty": "Easy" | "Moderate" | "Challenging" | "Expert" | null,
        "pruning": {
            "bestTime": "string",
            "notes": "string | null"
        },
        "health": {
            "status": "Healthy" | "Over-watered" | "Under-watered" | "Pest-damaged" | "Nutrient-deficient" | "Root-bound" | "Mixed" | "Unknown",
            "summary": "string (description en une phrase)"
        },
        "taxonomy": {
            "genus": "string",
            "scientificName": "string",
            "commonNames": ["string", "string"] // DOIT être un tableau, même avec un seul élément
        },
        "description": {
            "short": "string (exactement 4 lignes, 60-80 caractères chacune)",
            "long": "string (2-3 paragraphes)"
        },
        "watering": {
            "short": "string (règle générale en 1 phrase)",
            "long": "string (calendrier détaillé)",
            "reminderDays": "integer (nombre de jours d'arrosage)"
        },
        "temperature": {
            "celsiusRange": "string (format: min-max °C)",
            "fahrenheitRange": "string (format: min-max °F)"
        },
        "sunlight": {
            "short": "string (1 phrase)",
            "long": "string (conseils détaillés)"
        },
        "soil": {
            "type": "string",
            "drainage": "Fast" | "Moderate" | "Slow"
        },
        "humidity": {
            "rangePercent": "string (format: min-max %)",
            "long": "string"
        },
        "repotting": {
            "short": "string (1 phrase)",
            "long": "string (instructions détaillées)"
        },
        "fertilizer": {
            "short": "string (1 phrase)",
            "long": "string (instructions détaillées)"
        },
        "bloom": {
            "season": "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown",
            "hue": "string | null",
            "fragrance": "fragrant" | "non-fragrant" | "subtle" | "unknown"
        },
        "pestsDiseases": {
            "common": ["string"], // DOIT être un tableau
            "quickFixes": ["string"] // DOIT être un tableau
        },
        "airBenefit": {
            "short": "string (1 ligne)",
            "long": "string (paragraphe)"
        },
        "funFact": {
            "short": "string (1 ligne)",
            "long": "string (paragraphe)"
        }
        }
        """
    case "de":
        return """
        AUFGABE  
        1. Identifizieren Sie die Pflanze im Bild so genau wie möglich.  
        2. Füllen Sie JEDES Feld unten aus und folgen Sie EXAKT dem angegebenen Format.
        3. Geben Sie **nur** gültiges JSON zurück (kein Markdown, Kommentare oder zusätzliche Schlüssel).  
        4. Fügen Sie keinen erklärenden Text außerhalb des JSON hinzu.
        5. Befolgen Sie die Aufzählungswerte EXAKT wie angegeben.
        6. Verwenden Sie niemals das Zeichen 0xa
        7. WICHTIG: Antworten Sie auf Deutsch für alle Textwerte im JSON.
        8. Make sure that pre-defined value like "Toxic" | "Non-toxic" | "Unknown" or "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown" etc, will still be returned in English.
        
        JSON-SCHEMA (exakte Schlüsselreihenfolge und Werte)  
        {
        "name": "string",
        "family": "string",
        "poisonous": {
            "isPoisonous": boolean | null,
            "details": "string | null"
        },
        "petToxicity": {
            "cats": "Toxic" | "Non-toxic" | "Unknown",
            "dogs": "Toxic" | "Non-toxic" | "Unknown",
            "other": "string | null"
        },
        "careDifficulty": "Easy" | "Moderate" | "Challenging" | "Expert" | null,
        "pruning": {
            "bestTime": "string",
            "notes": "string | null"
        },
        "health": {
            "status": "Healthy" | "Over-watered" | "Under-watered" | "Pest-damaged" | "Nutrient-deficient" | "Root-bound" | "Mixed" | "Unknown",
            "summary": "string (Einzeilige Beschreibung)"
        },
        "taxonomy": {
            "genus": "string",
            "scientificName": "string",
            "commonNames": ["string", "string"] // MUSS ein Array sein, auch mit nur einem Element
        },
        "description": {
            "short": "string (genau 4 Zeilen, 60-80 Zeichen pro Zeile)",
            "long": "string (2-3 Absätze)"
        },
        "watering": {
            "short": "string (1-Satz Faustregel)",
            "long": "string (detaillierter Zeitplan)",
            "reminderDays": "integer (Anzahl der Tage für Bewässerung)"
        },
        "temperature": {
            "celsiusRange": "string (Format: min-max °C)",
            "fahrenheitRange": "string (Format: min-max °F)"
        },
        "sunlight": {
            "short": "string (1 Satz)",
            "long": "string (erweiterte Anleitung)"
        },
        "soil": {
            "type": "string",
            "drainage": "Fast" | "Moderate" | "Slow"
        },
        "humidity": {
            "rangePercent": "string (Format: min-max %)",
            "long": "string"
        },
        "repotting": {
            "short": "string (1 Satz)",
            "long": "string (erweiterte Anweisungen)"
        },
        "fertilizer": {
            "short": "string (1 Satz)",
            "long": "string (erweiterte Anweisungen)"
        },
        "bloom": {
            "season": "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown",
            "hue": "string | null",
            "fragrance": "fragrant" | "non-fragrant" | "subtle" | "unknown"
        },
        "pestsDiseases": {
            "common": ["string"], // MUSS ein Array sein
            "quickFixes": ["string"] // MUSS ein Array sein
        },
        "airBenefit": {
            "short": "string (1 Zeile)",
            "long": "string (Absatz)"
        },
        "funFact": {
            "short": "string (1 Zeile)",
            "long": "string (Absatz)"
        }
        }
        """
    case "it":
        return """
        COMPITO  
        1. Identifica la pianta nell'immagine nel modo più preciso possibile.  
        2. Compila OGNI campo seguendo ESATTAMENTE il formato specificato.
        3. Restituisci **solo** JSON valido (niente markdown, commenti o chiavi extra).  
        4. Non aggiungere testo esplicativo al di fuori del JSON.
        5. Segui ESATTAMENTE i valori enum specificati.
        6. Non usare mai il carattere 0xa
        7. IMPORTANTE: Rispondi in italiano per tutti i valori testuali nel JSON.
        8. Make sure that pre-defined value like "Toxic" | "Non-toxic" | "Unknown" or "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown" etc, will still be returned in English.
        
        SCHEMA JSON (ordine esatto delle chiavi e valori)  
        {
        "name": "string",
        "family": "string",
        "poisonous": {
            "isPoisonous": boolean | null,
            "details": "string | null"
        },
        "petToxicity": {
            "cats": "Toxic" | "Non-toxic" | "Unknown",
            "dogs": "Toxic" | "Non-toxic" | "Unknown",
            "other": "string | null"
        },
        "careDifficulty": "Easy" | "Moderate" | "Challenging" | "Expert" | null,
        "pruning": {
            "bestTime": "string",
            "notes": "string | null"
        },
        "health": {
            "status": "Healthy" | "Over-watered" | "Under-watered" | "Pest-damaged" | "Nutrient-deficient" | "Root-bound" | "Mixed" | "Unknown",
            "summary": "string (descrizione di una frase)"
        },
        "taxonomy": {
            "genus": "string",
            "scientificName": "string",
            "commonNames": ["string", "string"] // DEVE essere un array, anche con un solo elemento
        },
        "description": {
            "short": "string (esattamente 4 righe, 60-80 caratteri ciascuna)",
            "long": "string (2-3 paragrafi)"
        },
        "watering": {
            "short": "string (regola pratica in 1 frase)",
            "long": "string (programma dettagliato)",
            "reminderDays": "integer (numero di giorni per l'innaffiatura)"
        },
        "temperature": {
            "celsiusRange": "string (formato: min-max °C)",
            "fahrenheitRange": "string (formato: min-max °F)"
        },
        "sunlight": {
            "short": "string (1 frase)",
            "long": "string (guida dettagliata)"
        },
        "soil": {
            "type": "string",
            "drainage": "Fast" | "Moderate" | "Slow"
        },
        "humidity": {
            "rangePercent": "string (formato: min-max %)",
            "long": "string"
        },
        "repotting": {
            "short": "string (1 frase)",
            "long": "string (istruzioni dettagliate)"
        },
        "fertilizer": {
            "short": "string (1 frase)",
            "long": "string (istruzioni dettagliate)"
        },
        "bloom": {
            "season": "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown",
            "hue": "string | null",
            "fragrance": "fragrant" | "non-fragrant" | "subtle" | "unknown"
        },
        "pestsDiseases": {
            "common": ["string"], // DEVE essere un array
            "quickFixes": ["string"] // DEVE essere un array
        },
        "airBenefit": {
            "short": "string (1 riga)",
            "long": "string (paragrafo)"
        },
        "funFact": {
            "short": "string (1 riga)",
            "long": "string (paragrafo)"
        }
        }
        """
    case "pl":
        return """
        ZADANIE  
        1. Zidentyfikuj roślinę na zdjęciu tak dokładnie, jak to możliwe.  
        2. Wypełnij KAŻDE pole poniżej, postępując DOKŁADNIE według określonego formatu.
        3. Zwróć **tylko** prawidłowy JSON (bez markdown, komentarzy lub dodatkowych kluczy).  
        4. Nie dodawaj tekstu wyjaśniającego poza JSON.
        5. Postępuj DOKŁADNIE według określonych wartości wyliczeniowych.
        6. Nigdy nie używaj znaku 0xa
        7. WAŻNE: Odpowiadaj po polsku dla wszystkich wartości tekstowych w JSON.
        8. Make sure that pre-defined value like "Toxic" | "Non-toxic" | "Unknown" or "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown" etc, will still be returned in English.
        
        SCHEMAT JSON (dokładna kolejność kluczy i wartości)  
        {
        "name": "string",
        "family": "string",
        "poisonous": {
            "isPoisonous": boolean | null,
            "details": "string | null"
        },
        "petToxicity": {
            "cats": "Toxic" | "Non-toxic" | "Unknown",
            "dogs": "Toxic" | "Non-toxic" | "Unknown",
            "other": "string | null"
        },
        "careDifficulty": "Easy" | "Moderate" | "Challenging" | "Expert" | null,
        "pruning": {
            "bestTime": "string",
            "notes": "string | null"
        },
        "health": {
            "status": "Healthy" | "Over-watered" | "Under-watered" | "Pest-damaged" | "Nutrient-deficient" | "Root-bound" | "Mixed" | "Unknown",
            "summary": "string (jednozdaniowy opis)"
        },
        "taxonomy": {
            "genus": "string",
            "scientificName": "string",
            "commonNames": ["string", "string"] // MUSI być tablicą, nawet z jednym elementem
        },
        "description": {
            "short": "string (dokładnie 4 linie, 60-80 znaków każda)",
            "long": "string (2-3 akapity)"
        },
        "watering": {
            "short": "string (1-zdaniowa zasada ogólna)",
            "long": "string (szczegółowy harmonogram)",
            "reminderDays": "integer (liczba dni podlewania)"
        },
        "temperature": {
            "celsiusRange": "string (format: min-max °C)",
            "fahrenheitRange": "string (format: min-max °F)"
        },
        "sunlight": {
            "short": "string (1 zdanie)",
            "long": "string (rozszerzone wskazówki)"
        },
        "soil": {
            "type": "string",
            "drainage": "Fast" | "Moderate" | "Slow"
        },
        "humidity": {
            "rangePercent": "string (format: min-max %)",
            "long": "string"
        },
        "repotting": {
            "short": "string (1 zdanie)",
            "long": "string (rozszerzone instrukcje)"
        },
        "fertilizer": {
            "short": "string (1 zdanie)",
            "long": "string (rozszerzone instrukcje)"
        },
        "bloom": {
            "season": "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown",
            "hue": "string | null",
            "fragrance": "fragrant" | "non-fragrant" | "subtle" | "unknown"
        },
        "pestsDiseases": {
            "common": ["string"], // MUSI być tablicą
            "quickFixes": ["string"] // MUSI być tablicą
        },
        "airBenefit": {
            "short": "string (1 linia)",
            "long": "string (akapit)"
        },
        "funFact": {
            "short": "string (1 linia)",
            "long": "string (akapit)"
        }
        }
        """
    case "es":
        return """
        TAREA  
        1. Identifica la planta en la imagen con la mayor precisión posible.  
        2. Completa TODOS los campos siguiendo EXACTAMENTE el formato especificado.
        3. Devuelve **solo** JSON válido (sin markdown, comentarios o claves adicionales).  
        4. No agregues texto explicativo fuera del JSON.
        5. Sigue EXACTAMENTE los valores de enumeración especificados.
        6. Nunca uses el carácter 0xa
        7. IMPORTANTE: Responde en español para todos los valores de texto en el JSON.
        8. Make sure that pre-defined value like "Toxic" | "Non-toxic" | "Unknown" or "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown" etc, will still be returned in English.
        
        ESQUEMA JSON (orden y valores exactos de las claves)  
        {
        "name": "string",
        "family": "string",
        "poisonous": {
            "isPoisonous": boolean | null,
            "details": "string | null"
        },
        "petToxicity": {
            "cats": "Toxic" | "Non-toxic" | "Unknown",
            "dogs": "Toxic" | "Non-toxic" | "Unknown",
            "other": "string | null"
        },
        "careDifficulty": "Easy" | "Moderate" | "Challenging" | "Expert" | null,
        "pruning": {
            "bestTime": "string",
            "notes": "string | null"
        },
        "health": {
            "status": "Healthy" | "Over-watered" | "Under-watered" | "Pest-damaged" | "Nutrient-deficient" | "Root-bound" | "Mixed" | "Unknown",
            "summary": "string (descripción de una frase)"
        },
        "taxonomy": {
            "genus": "string",
            "scientificName": "string",
            "commonNames": ["string", "string"] // DEBE ser un array, incluso con un solo elemento
        },
        "description": {
            "short": "string (exactamente 4 líneas, 60-80 caracteres cada una)",
            "long": "string (2-3 párrafos)"
        },
        "watering": {
            "short": "string (regla general en 1 frase)",
            "long": "string (calendario detallado)",
            "reminderDays": "integer (cantidad de días de riego)"
        },
        "temperature": {
            "celsiusRange": "string (formato: min-max °C)",
            "fahrenheitRange": "string (formato: min-max °F)"
        },
        "sunlight": {
            "short": "string (1 frase)",
            "long": "string (guía ampliada)"
        },
        "soil": {
            "type": "string",
            "drainage": "Fast" | "Moderate" | "Slow"
        },
        "humidity": {
            "rangePercent": "string (formato: min-max %)",
            "long": "string"
        },
        "repotting": {
            "short": "string (1 frase)",
            "long": "string (instrucciones ampliadas)"
        },
        "fertilizer": {
            "short": "string (1 frase)",
            "long": "string (instrucciones ampliadas)"
        },
        "bloom": {
            "season": "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown",
            "hue": "string | null",
            "fragrance": "fragrant" | "non-fragrant" | "subtle" | "unknown"
        },
        "pestsDiseases": {
            "common": ["string"], // DEBE ser un array
            "quickFixes": ["string"] // DEBE ser un array
        },
        "airBenefit": {
            "short": "string (1 línea)",
            "long": "string (párrafo)"
        },
        "funFact": {
            "short": "string (1 línea)",
            "long": "string (párrafo)"
        }
        }
        """
    default:
        return """
        TASK  
        1. Identify the plant in the image as precisely as possible.  
        2. Populate EVERY field below following the EXACT format specified.
        3. Return **only** valid JSON (no markdown, comments, or extra keys).  
        4. Do not add explanatory text outside the JSON.
        5. Follow the enum values EXACTLY as specified.
        6. Never use 0xa character
        7. IMPORTANT: Respond in English for all text values in the JSON.
        8. Make sure that pre-defined value like "Toxic" | "Non-toxic" | "Unknown" or "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown" etc, will still be returned in English.
        
        JSON SCHEMA (exact key order and values)  
        {
        "name": "string",
        "family": "string",
        "poisonous": {
            "isPoisonous": boolean | null,
            "details": "string | null"
        },
        "petToxicity": {
            "cats": "Toxic" | "Non-toxic" | "Unknown",
            "dogs": "Toxic" | "Non-toxic" | "Unknown",
            "other": "string | null"
        },
        "careDifficulty": "Easy" | "Moderate" | "Challenging" | "Expert" | null,
        "pruning": {
            "bestTime": "string",
            "notes": "string | null"
        },
        "health": {
            "status": "Healthy" | "Over-watered" | "Under-watered" | "Pest-damaged" | "Nutrient-deficient" | "Root-bound" | "Mixed" | "Unknown",
            "summary": "string (one-sentence description)"
        },
        "taxonomy": {
            "genus": "string",
            "scientificName": "string",
            "commonNames": ["string", "string"] // MUST be an array, even with one item
        },
        "description": {
            "short": "string (exactly 4 lines, 60-80 chars each)",
            "long": "string (2-3 paragraphs)"
        },
        "watering": {
            "short": "string (1-sentence rule of thumb)",
            "long": "string (detailed schedule)",
            "reminderDays": "integer (amount of days of watering)"
        },
        "temperature": {
            "celsiusRange": "string (format: min-max °C)",
            "fahrenheitRange": "string (format: min-max °F)"
        },
        "sunlight": {
            "short": "string (1-sentence)",
            "long": "string (expanded guidance)"
        },
        "soil": {
            "type": "string",
            "drainage": "Fast" | "Moderate" | "Slow"
        },
        "humidity": {
            "rangePercent": "string (format: min-max %)",
            "long": "string"
        },
        "repotting": {
            "short": "string (1-sentence)",
            "long": "string (expanded instructions)"
        },
        "fertilizer": {
            "short": "string (1-sentence)",
            "long": "string (expanded instructions)"
        },
        "bloom": {
            "season": "spring" | "summer" | "autumn" | "winter" | "year-round" | "none" | "unknown",
            "hue": "string | null",
            "fragrance": "fragrant" | "non-fragrant" | "subtle" | "unknown"
        },
        "pestsDiseases": {
            "common": ["string"], // MUST be an array
            "quickFixes": ["string"] // MUST be an array
        },
        "airBenefit": {
            "short": "string (1 line)",
            "long": "string (paragraph)"
        },
        "funFact": {
            "short": "string (1 line)",
            "long": "string (paragraph)"
        }
        }
        """
    }
}
