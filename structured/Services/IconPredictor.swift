import Foundation

enum IconPredictor {
    private static let keywordMap: [(keywords: [String], icon: String)] = [
        // Fitness
        (["gym", "workout", "exercise", "lift", "weight", "dumbbell"], "dumbbell.fill"),
        (["run", "running", "jog", "jogging", "sprint"], "figure.run"),
        (["walk", "walking", "stroll", "hike"], "figure.walk"),
        (["yoga", "stretch", "meditat"], "figure.yoga"),
        (["swim", "pool"], "figure.pool.swim"),
        (["bike", "cycle", "cycling", "bicycle"], "bicycle"),
        (["badminton", "tennis", "squash", "racket"], "figure.badminton"),
        (["basketball", "cricket", "football", "soccer", "sport"], "sportscourt.fill"),

        // Work & Communication
        (["meeting", "standup", "sync", "1:1", "huddle"], "person.2.fill"),
        (["call", "phone", "dial"], "phone.fill"),
        (["email", "mail", "inbox", "reply"], "envelope.fill"),
        (["message", "chat", "text", "dm", "slack"], "message.fill"),
        (["present", "presentation", "slides", "pitch", "demo"], "chart.bar.fill"),
        (["brainstorm", "idea", "think"], "lightbulb.fill"),
        (["interview", "hire", "recruit"], "person.crop.rectangle.fill"),

        // Learning & Creative
        (["read", "book", "study", "learn", "research", "article"], "book.fill"),
        (["write", "blog", "journal", "essay", "draft"], "pencil"),
        (["code", "dev", "program", "debug", "deploy", "ship"], "desktopcomputer"),
        (["design", "figma", "sketch", "ui", "ux", "mockup"], "paintbrush.fill"),
        (["music", "practice", "piano", "guitar", "sing"], "music.note"),
        (["photo", "camera", "shoot", "picture"], "camera.fill"),

        // Food & Drink
        (["cook", "dinner", "lunch", "breakfast", "meal", "recipe", "food"], "fork.knife"),
        (["coffee", "tea", "cafe", "espresso"], "cup.and.saucer.fill"),
        (["water", "drink", "hydrate"], "drop.fill"),
        (["snack", "fruit", "eat"], "carrot.fill"),

        // Errands & Home
        (["shop", "buy", "grocery", "store", "market", "order"], "cart.fill"),
        (["clean", "tidy", "organize", "declutter", "laundry", "wash"], "sparkles"),
        (["pack", "move", "box"], "shippingbox.fill"),
        (["fix", "repair", "maintenance", "plumber", "electrician"], "wrench.fill"),

        // Health & Wellness
        (["sleep", "nap", "rest", "bed"], "bed.double.fill"),
        (["doctor", "dentist", "health", "appointment", "checkup"], "cross.case.fill"),
        (["pill", "medicine", "vitamin", "supplement"], "pills.fill"),

        // Travel & Transport
        (["drive", "car", "commute", "travel", "trip"], "car.fill"),
        (["flight", "fly", "airport", "plane"], "airplane"),
        (["train", "metro", "subway", "bus"], "tram.fill"),

        // Entertainment & Social
        (["game", "play", "gaming"], "gamecontroller.fill"),
        (["movie", "film", "watch", "netflix", "show", "tv"], "tv.fill"),
        (["party", "celebrate", "birthday"], "party.popper.fill"),
        (["gift", "present"], "gift.fill"),

        // Finance & Admin
        (["pay", "bill", "bank", "finance", "money", "budget", "tax"], "dollarsign.circle.fill"),
        (["plan", "goal", "review", "reflect"], "target"),

        // Pets & Nature
        (["pet", "dog", "cat", "vet"], "pawprint.fill"),
        (["garden", "plant", "water plant"], "leaf.fill"),

        // Spiritual
        (["pray", "church", "temple", "worship", "meditation"], "hands.sparkles.fill"),
    ]

    /// Returns a predicted SF Symbol icon name based on the task title, or nil if no match.
    static func predict(for title: String) -> String? {
        let lower = title.lowercased()
        for entry in keywordMap {
            for keyword in entry.keywords {
                if lower.contains(keyword) {
                    return entry.icon
                }
            }
        }
        return nil
    }
}
