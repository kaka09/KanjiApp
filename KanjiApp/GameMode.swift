import UIKit
import CoreData
import AVFoundation

//class CardStateEntry {
//    var index: NSNumber
//    var answersKnown: NSNumber
//    var answersNormal: NSNumber
//    var answersHard: NSNumber
//    var answersForgot: NSNumber
//    var interval: NSNumber
//    var dueTime: NSNumber
//    var enabled: NSNumber
//    var suspended: NSNumber
//    var known: NSNumber
//}

class GameMode: CustomUIViewController, AVAudioPlayerDelegate {
    @IBOutlet var outputText: UITextView!
    
    var due: [NSNumber] = []
    var undoStack: [NSNumber] = []
    var isFront: Bool = true
    var isBack: Bool {
    get {
        return !isFront
    }
    }
    var audioPlayer = AVAudioPlayer()
    
    @IBOutlet weak var leftIndicator: UILabel!
    @IBOutlet weak var middleIndicator: UILabel!
    @IBOutlet weak var rightIndicator: UILabel!
    
    @IBOutlet weak var addRemoveSidebar: UIView!
    @IBOutlet weak var kanjiView: UILabel!
    
    var edgeReveal: EdgeReveal! = nil
    
    var dueCard: Card? {
    get {
        if due.count > 0 {
            return managedObjectContext.fetchCardByIndex(due[0])
        }
        return nil
    }
    }
    
    required init(coder aDecoder: NSCoder!) {
//        self.due = []
        super.init(coder: aDecoder)
    }
    
    var cardPropertiesSidebar: CardPropertiesSidebar {
        return self.childViewControllers[0] as CardPropertiesSidebar
    }
    
    var backTextCache: NSAttributedString! = nil

    func updateText() {
        if let card = dueCard {
            if isFront {
                card.setFrontText(kanjiView)
                outputText.text = ""
                backTextCache = card.back
            }
            else {
                if backTextCache == nil {
                    backTextCache = card.back
                }

                kanjiView.text = ""
                outputText.attributedText = backTextCache
                backTextCache = nil
            }
            kanjiView.hidden = !isFront
            outputText.textAlignment = .Center
            outputText.textContainerInset.top = 40
            outputText.scrollRangeToVisible(NSRange(location: 0, length: 1))
            
            kanjiView.enabled = isFront
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEdgeReveal()
        
        leftIndicator.hidden = true
        middleIndicator.hidden = true
        rightIndicator.hidden = true
        
        var onTouchGesture = UITapGestureRecognizer(target: self, action: "onTouch:")
        outputText.addGestureRecognizer(onTouchGesture)
    }
    
    override func addNotifications() {
        super.addNotifications()
        
        Globals.notificationEditCardProperties.addObserver(self, selector: "onEditCard", object: nil)
        
        Globals.notificationSidebarInteract.addObserver(self, selector: "onSidebarInteract", object: nil)
        
    }
    
    private func answerCard(answer: AnswerDifficulty) {
        if let card = dueCard {
            var highlightLabel: UILabel! = nil
            
            switch answer {
            case .Forgot:
                highlightLabel = leftIndicator
                card.answerCard(.Forgot)
            case .Normal:
                highlightLabel = middleIndicator
                card.answerCard(.Normal)
            case .Hard:
                highlightLabel = rightIndicator
                card.answerCard(.Hard)
            default:
                break
            }
            
            highlightLabel.hidden = false
            highlightLabel.alpha = 1
            
            UIView.animateWithDuration(0.25,
                delay: 0,
                options: UIViewAnimationOptions.CurveEaseIn,
                animations: {
                    highlightLabel.alpha = 0
                },
                completion: {
                    (_) -> () in
                    highlightLabel.hidden = true
                    self.onHighlightAnimationFinish()
            })
            
            saveContext()
        }
        
        advanceCard()
    }
    
    func onTouch(sender: UITapGestureRecognizer) {
        if !isFront {
            var x = sender.locationInView(self.view).x / Globals.screenSize.width
            x *= 3
            
            if x >= 0 && x < 1 {
                answerCard(.Forgot)
            } else if x >= 1 && x <= 2 {
                answerCard(.Normal)
            } else {
                answerCard(.Hard)
            }
        } else {
            advanceCard()
        }
    }
    
    private func onHighlightAnimationFinish() {
        updateText()
        
        if due.count == 0 {
            Globals.notificationTransitionToView.postNotification(.CardsFinished)
        }
    }
    
    func onEditCard() {
        if !view.hidden {
            edgeReveal.editCardProperties(dueCard, value: Globals.notificationEditCardProperties.value)
            
            saveContext()
        }
    }
    
    private var processUndo = false
    
    private func setupEdgeReveal() {
        edgeReveal = EdgeReveal(
            parent: view,
            revealType: .Right,
            onUpdate: {(offset: CGFloat) -> () in
                self.outputText.frame.origin.x = -offset
                self.addRemoveSidebar.frame.origin.x = Globals.screenSize.width - offset
                self.kanjiView.frame.origin.x = -offset
                self.cardPropertiesSidebar.animate(offset)
            },
            setVisible: {(visible: Bool, completed: Bool) -> () in
                if let card = self.dueCard {
                    self.cardPropertiesSidebar.updateContents(
                        card,
                        showUndoButton: self.undoStack.count > 0,
                        onUndoButtonTap: {
                        self.edgeReveal.animateSelf(false)
                        self.processUndo = true
                    })
                }
                self.addRemoveSidebar.hidden = !visible
                
                if !visible && self.processUndo {
                    self.processUndo = false
                    self.backTextCache = nil
                    self.onUndo()
                }
        })
        
        edgeReveal.onTap = {(open: Bool) -> () in
            if !open && !self.isFront {
                self.answerCard(.Hard)
            } else {
                self.advanceCard()
            }
        }
    }
    
    private func onUndo() {
//        println("undo")
        if undoStack.count > 0 {
            var remove = undoStack.removeLast()
            
            due.insert(remove, atIndex: 0)
            
//            println(managedObjectContext.undoManager.undoActionName)
            managedObjectContext.undoManager.undo()
            
            isFront = true
            updateText()
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchCards()
        updateText()
    }
    
    private func fetchCards(clearUndoStack: Bool = true) {
        var fetchAheadAmount: Double = 0
        
        switch Globals.notificationTransitionToView.value {
        case .GameMode(let studyAheadAmount):
            fetchAheadAmount = studyAheadAmount
        default:
            break
        }
        
        due = managedObjectContext.fetchCardsDue(fetchAheadAmount: fetchAheadAmount).map { ($0 as Card).index }
        if clearUndoStack {
            undoStack = []
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if due.count == 0 {
            Globals.notificationTransitionToView.postNotification(.CardsFinished)
        }
    }
    
    func advanceCard() {
//        if !isFront {
//            println("\(dueCard?.kanji) dueTime = \(dueCard?.interval)")
//        }
        
        if isBack && due.count >= 1 {
            var remove = due.removeAtIndex(0)
            undoStack.append(remove)
        }
        
        if due.count == 0 {
            fetchCards(clearUndoStack: false)
        }
        
        if due.count != 0 {
            isFront = !isFront
            
//            if isBack {
//                println("\(dueCard?.kanji) dueTime = \(dueCard?.interval)")
//            }
            
            if isBack {
                if var path = dueCard?.embeddedData.soundWord {
                    playSound(filterSoundPath(path))
                }
                
                updateText()
            }
        }
    }
    
    func filterSoundPath(path: String) -> String {
        var range: NSRange = NSRange(location: 7, length: countElements(path) - 12)
        return (path as NSString).substringWithRange(range)
    }
    
    func playSound(name: String, fileType: String = "mp3", var sendEvents: Bool = true) {
        if settings.volume != 0 {
            var resourcePath = NSBundle.mainBundle().pathForResource(name, ofType: fileType)
            
            if let resourcePath = resourcePath {
                var sound = NSURL(fileURLWithPath: resourcePath)
                
                var error:NSError?
                audioPlayer = AVAudioPlayer(contentsOfURL: sound, error: &error)
                if sendEvents {
                    audioPlayer.delegate = self
                }
                audioPlayer.play()
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        
        if var path = dueCard?.embeddedData.soundDefinition {
            if !isFront {
                playSound(filterSoundPath(path), sendEvents: false)
            }
        }
    }
    
    func onSidebarInteract() {
        edgeReveal.animateSelf(false)
    }
    
//    func onInteract(interactType: InteractType, _ card: Card) {
//        switch interactType {
//        case .Tap:
//            //            card.answerCard(.Normal)
//            break
//        case .SwipeRight:
////            println("Swiped right \(card.kanji)")
////            card.answerCard(.Hard)
//            //            due.append(due[0])
//            break
//        case .SwipeLeft:
////            println("Swiped Left \(card.kanji)")
////            card.answerCard(.Forgot)
//            //            due.append(due[0])
//            break
//        case .SwipeUp:
//            break
////            println("Swiped Up \(card.kanji)")
////            card.answerCard(.Easy)
//        case .SwipeDown:
//            break
////            println("Swipe Down \(card.kanji)")
//        }
//        advanceCard()
//        saveContext()
//    }
    
    
//    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
//        
//        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
//            if !isFront {
//                if let card = dueCard {
//                    switch swipeGesture.direction {
//                        
//                    case UISwipeGestureRecognizerDirection.Right:
//                        onInteract(.SwipeRight, card)
//                        
//                    case UISwipeGestureRecognizerDirection.Down:
//                        onInteract(.SwipeDown, card)
//                        
//                    case UISwipeGestureRecognizerDirection.Up:
//                        onInteract(.SwipeUp, card)
//                        
//                    case UISwipeGestureRecognizerDirection.Left:
//                        onInteract(.SwipeLeft, card)
//                        
//                    default:
//                        break
//                    }
//                }
//            }
//        }
//    }
    
//    func setupSwipeGestures() {
////        var swipeRight = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
////        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
////        self.view.addGestureRecognizer(swipeRight)
////        
////        var swipeDown = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
////        swipeDown.direction = UISwipeGestureRecognizerDirection.Down
////        self.view.addGestureRecognizer(swipeDown)
////        
////        var swipeUp = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
////        swipeUp.direction = UISwipeGestureRecognizerDirection.Up
////        self.view.addGestureRecognizer(swipeUp)
////        
////        var swipeLeft = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
////        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
////        self.view.addGestureRecognizer(swipeLeft)
//    }
}