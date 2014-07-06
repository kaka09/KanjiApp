import UIKit
import CoreData

enum CardProperties {
    case kanji
    case index
    case hiragana
    case definition
    case exampleEnglish
    case exampleJapanese
    case soundWord
    case soundDefinition
    case definitionOther
    case usageAmount
    case usageAmountOther
    case pitchAccentText
    case pitchAccent
    case otherExampleSentences
    
    case answersKnown
    case answersNormal
    case answersHard
    case answersForgot
    case interval
    func description() -> String {
        switch self {
        case .kanji:
            return "kanji"
        case .index:
            return "index"
        case .hiragana:
            return "hiragana"
        case .definition:
            return "definition"
        case .exampleEnglish:
            return "exampleEnglish"
        case .exampleJapanese:
            return "exampleJapanese"
        case .soundWord:
            return "soundWord"
        case .soundDefinition:
            return "soundDefinition"
        case .definitionOther:
            return "definitionOther"
        case .definitionOther:
            return "definitionOther"
        case .usageAmount:
            return "usageAmount"
        case .usageAmountOther:
            return "usageAmountOther"
        case .pitchAccentText:
            return "pitchAccentText"
        case .pitchAccent:
            return "pitchAccent"
        case .otherExampleSentences:
            return "otherExampleSentences"
        case .answersKnown:
            return "answersKnown"
        case .answersNormal:
            return "answersNormal"
        case .answersHard:
            return "answersHard"
        case .answersForgot:
            return "answersForgot"
        case .interval:
            return "interval"
        }
    }
}

@objc(Card)
class Card: NSManagedObject {
    @NSManaged var kanji: String
    @NSManaged var index: NSNumber
    @NSManaged var hiragana: String
    @NSManaged var definition: String
    @NSManaged var exampleEnglish: String
    @NSManaged var exampleJapanese: String
    @NSManaged var soundWord: String
    @NSManaged var soundDefinition: String
    @NSManaged var definitionOther: String
    @NSManaged var usageAmount: NSNumber
    @NSManaged var usageAmountOther: NSNumber
    @NSManaged var pitchAccentText: String
    @NSManaged var pitchAccent: NSNumber
    @NSManaged var otherExampleSentences: String

    @NSManaged var answersKnown: NSNumber
    @NSManaged var answersNormal: NSNumber
    @NSManaged var answersHard: NSNumber
    @NSManaged var answersForgot: NSNumber
    @NSManaged var interval: NSNumber
    @NSManaged var dueTime: NSNumber
    @NSManaged var enabled: NSNumber
    
    func answerCard(difficulty: AnswerDifficulty)
    {
        switch difficulty {
        case .Easy:
            println("Easy")
            interval = 9
        case .Normal:
            println("Normal")
            if interval.integerValue < 12
            {
                interval = interval.doubleValue + 1
            }
        case .Hard:
            println("Hard")
            if interval.integerValue >= 1
            {
                interval = interval.doubleValue - 1
            }
        case .Forgot:
            println("Forgot")
            interval = interval.doubleValue / 2
            
        }
    }
    
    var front: NSAttributedString {
    get {
        let font = "HiraKakuProN-W3"
        var value = NSMutableAttributedString()

        value.beginEditing()
        
        let baseSize: Double = 210
        
        var size = baseSize * 2 / Double(countElements(kanji))
        
        if size > baseSize
        {
            size = baseSize
        }
        
        for char in kanji
        {
            value.addAttributedText(char + "", NSFontAttributeName, UIFont(name: font, size: CGFloat(size)))
        }
        
        var style = NSMutableParagraphStyle()
        style.lineSpacing = -size * 0.3
//        style.paragraphSpacing = 0
//        style.lineSpacing = 0
        //style.maximumLineHeight = size / 1.5
        
        var rangle = NSMakeRange(0, value.mutableString.length)
        
        value.addAttribute(NSParagraphStyleAttributeName, value: style, range: rangle)

        value.endEditing()

        return value
    }
    }

    var back: NSAttributedString {
    get {
        let font = "HiraKakuProN-W3"
        var value = NSMutableAttributedString()
        
        value.beginEditing()

        value.addAttributedText(hiragana, NSFontAttributeName, UIFont(name: font, size: 50))

        value.addBreak(5)

        value.addAttributedText(definition, NSFontAttributeName, UIFont(name: font, size: 22))

        value.addBreak(20)

        value.addAttributedText(exampleJapanese, NSFontAttributeName, UIFont(name: font, size: 24), processAttributes: true, removeSpaces: true)

        value.addBreak(5)

        value.addAttributedText(exampleEnglish, NSFontAttributeName, UIFont(name: font, size: 16))

        value.addBreak(15)
        
        value.addAttributedText(otherExampleSentences, NSFontAttributeName, UIFont(name: font, size: 18), processAttributes: true)
        
        value.addBreak(10)
        
        value.addAttributedText("\(pitchAccent)", NSFontAttributeName, UIFont(name: font, size: 16))

        //'#000000', '#CC0066', '#0099EE', '#11AA00', '#FF6600', '#990099', '#999999', '#000000', '#000000', '#000000'

        var color = colorForPitchAccent(Int(pitchAccent))

        value.addAttribute(NSForegroundColorAttributeName, value: color, range: NSMakeRange(0, value.mutableString.length))


        value.endEditing()

        return value
    }
    }

    func colorForPitchAccent(pitchAccent: Int) -> UIColor
    {
        var color = UIColor(red: 0, green: 0, blue: 0, alpha: 1)

        switch pitchAccent {
        case 1:
            color = UIColor(red: 0.8125, green: 0, blue: 0.375, alpha: 1)

        case 2:
            color = UIColor(red: 0, green: 0.5625, blue: 0.9375, alpha: 1)

        case 3:
            color = UIColor(red: 1.0 / 16.0, green: 1.0 / 11.0, blue: 0, alpha: 1)

        case 4:
            color = UIColor(red: 1, green: 6.0 / 16.0, blue: 0, alpha: 1)

        case 5:
            color = UIColor(red: 9.0 / 16.0, green: 0, blue: 9.0 / 16.0, alpha: 1)

        case 6:
            color = UIColor(red: 9.0 / 16.0, green: 9.0 / 16.0, blue: 9.0 / 16.0, alpha: 1)

        default:
            color = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        }

        return color
    }

    var matches: NSArray = []
    
    class func createCard (propertyName:CardProperties, value:String, context: NSManagedObjectContext, checkForExisting: Bool = true) -> Card? {
        
        let entityName = "Card"
        
        if !value.isEmpty {
            if(checkForExisting)
            {
                let propertyType = propertyName.description()
                
                let request : NSFetchRequest = NSFetchRequest(entityName: entityName)
                
                request.returnsObjectsAsFaults = false
                request.predicate = NSPredicate(format: "\(propertyType) = %@", value)
                var error: NSError? = nil
                
                var matches: NSArray = context.executeFetchRequest(request, error: &error)
                
                if (matches.count > 1) {
                    return matches[0] as? Card
                }
            }
            
            let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)
            var card : Card = Card(entity: entityDescription, insertIntoManagedObjectContext: context)
            
            switch propertyName {
                case .kanji:
                        card.kanji = value
                default:
                    return card
            }
            return card
        }
        return nil
    }
}

extension NSMutableAttributedString {
    func addBreak(size: CGFloat)
    {
        if(size > 0)
        {
            self.addAttributedText(" ", NSFontAttributeName, UIFont(name: "Helvetica", size: size));
        }
    }
    
    func addAttributedText(var text: String, _ attributeName: String, _ object: AnyObject, breakLine: Bool = true, processAttributes: Bool = false, removeSpaces: Bool = false)
    {
        var bolds: NSRange[] = []
        
        if removeSpaces
        {
            text = removeFromString(text, " ")
        }
        
        if breakLine
        {
            text += "\n"
        }
        
        if processAttributes
        {
            var furiganaOpen = text.componentsSeparatedByString("]")
            
            text = ""
            for item in furiganaOpen
            {
                text += item.componentsSeparatedByString("[")[0]
            }
            
            text = removeFromString(text, "<b>")
            text = removeFromString(text, "</b>")
            text = replaceInString(text, "<br>", "\n")
            text = replaceInString(text, "&#39;", "'")
            text = replaceInString(text, "&quot;", "\"")
            text = removeFromString(text, "<span style=\"font-size:20px\">")
            text = removeFromString(text, "</span>")
            
//            var spanSizeOpen = text.componentsSeparatedByString("<span style=\"font-size:20px\">")
//            text = ""
//
//            for item in spanSizeOpen
//            {
//                var itemSplit = item.componentsSeparatedByString("</span>")
//                
//                for var i = 0; i < countElements(itemSplit); i++
//                {
//                    var previousSize = countElements(text)
//                    text += itemSplit[i]
//
//                    if i == 0
//                    {
//                        var color = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
//                        
//                        println(self.mutableString)
//                        
//                        var range: NSRange = NSMakeRange(self.mutableString.length, 2)
//                        self.addAttribute(NSBackgroundColorAttributeName, value: color, range: range)
//                    }
//                }
//            }
        }
        
        var existingLength: Int = self.mutableString.length
        var range: NSRange = NSMakeRange(existingLength, countElements(text))
        self.mutableString.appendString(text)
        
        self.addAttribute(attributeName, value: object, range: range)
    }
    
    func removeFromString(var value: String, _ remove: String) -> String
    {
        var items = value.componentsSeparatedByString(remove)
        
        value = ""
        for item in items
        {
            value += item
        }
        
        return value
    }
    
    func replaceInString(var value: String, _ remove: String, _ newValue: String) -> String
    {
        var items = value.componentsSeparatedByString(remove)
        
        value = ""
        var spacer = ""
        for item in items
        {
            value += spacer + item
            spacer = newValue
        }
        
        return value
    }
}
//
//// FETCH REQUESTS
//

func fetchCardsGeneral (entity : CoreDataEntities,
    property : CardProperties,
    context : NSManagedObjectContext) -> AnyObject[]?{
        
        let entityName = entity.description()
        let propertyName = property.description()
        
        let request :NSFetchRequest = NSFetchRequest(entityName: entityName)
        request.returnsObjectsAsFaults = false
        let sortDescriptor : NSSortDescriptor = NSSortDescriptor(key: CardProperties.interval.description(), ascending: true)
        request.sortDescriptors = [sortDescriptor]
        var error: NSError? = nil
        var matches: NSArray = context.executeFetchRequest(request, error: &error)
        
        if matches.count > 0 {
            return matches
        }
        else {
            return nil
        }
}

func fetchCards (property : CardProperties,
    value : String,
    context : NSManagedObjectContext) -> AnyObject[]? {
        
        let entity = CoreDataEntities.Card
        let entityName = entity.description()
        let propertyName = property.description()
        
        let request :NSFetchRequest = NSFetchRequest(entityName: entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "\(propertyName) = %@", value)
        let sortDescriptor :NSSortDescriptor = NSSortDescriptor(key: propertyName, ascending: true)
        request.sortDescriptors = [sortDescriptor]
        var error: NSError? = nil
        var matches: NSArray = context.executeFetchRequest(request, error: &error)
        
        if matches.count > 0 {
            return matches
        }
        else {
            return nil
        }
}

func fetchCardByKanji(kanji: String, context : NSManagedObjectContext) -> Card
{
    var value : AnyObject? = fetchCard(CardProperties.kanji, kanji, context)//self.managedObjectContext)
    
    return value as Card
}

func fetchCard (property : CardProperties,
    value : String,
    context : NSManagedObjectContext) -> AnyObject? {
        
        let entity = CoreDataEntities.Card
        let entityName = entity.description()
        let propertyName = property.description()
        
        let request :NSFetchRequest = NSFetchRequest(entityName: entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "\(propertyName) = %@", value)
        let sortDescriptor :NSSortDescriptor = NSSortDescriptor(key: propertyName, ascending: true)
        request.sortDescriptors = [sortDescriptor]
        var error: NSError? = nil
        var matches: NSArray = context.executeFetchRequest(request, error: &error)
        
        if matches.count > 0 {
            return matches[0]
        }
        else {
            return nil
        }
}

//
//// PRINT FETCH REQUEST
//

//func printFetchedArrayList (myarray:AnyObject[]) {
//    if myarray.count > 0 {
//        println("Has \(myarray.count) object")
//        for card : AnyObject in myarray {
//            var anObject = card as Card
//            //var thekanji = anObject.kanji
//            //println(thekanji)
//        }
//    }
//    else {
//        println("empty fetch")
//    }
//}