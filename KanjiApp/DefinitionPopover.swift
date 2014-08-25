import Foundation
import UIKit
import SpriteKit

var definitionPopoverInstance: DefinitionPopover? = nil

class DefinitionPopover : CustomUIViewController, UIGestureRecognizerDelegate {
    @IBOutlet var outputText: UITextView!
//    @IBOutlet weak var addRemoveButton: AddRemoveButton!
    @IBOutlet weak var addRemoveSidebar: UIView!
    @IBOutlet weak var definitionLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var studyingButton: UIButton!
    var rightEdgeReveal: EdgeReveal! = nil
    var leftEdgeReveal: EdgeReveal! = nil
    var propertiesSidebar: CardPropertiesSidebar {
        return self.childViewControllers[0] as CardPropertiesSidebar
    }
    
    var viewCard: Card? {
    get {
        return managedObjectContext.fetchCardByKanji(Globals.notificationShowDefinition.value)
    }
    }
    
    override var isGameView: Bool {
    get {
        return false
    }
    }
    
    class var instance: DefinitionPopover {
        get { return definitionPopoverInstance! }
    }
    
    required init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        
        definitionPopoverInstance = self
    }
    
    @IBAction func studyingPress(sender: AnyObject) {
        if rightEdgeReveal.animationState.IsOpenOrClosed() {
            rightEdgeReveal.animateSelf(!rightEdgeReveal.animationState.AnyOpen())
        }
    }
    
    @IBAction func backPress(sender: AnyObject) {
        Globals.notificationShowDefinition.postNotification("")
    }
    
//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        rightEdgeReveal.animateSelf(false)
//    }
//    
    func updateText() {
        if let card = viewCard {
            outputText.scrollRangeToVisible(NSRange(location: 0, length: 1))
            outputText.attributedText = card.definitionAttributedText
            outputText.textAlignment = .Center
            outputText.textContainerInset.top = 40
            outputText.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
            
            updateDefinitionLabel(card)
            propertiesSidebar.updateContents(card, showUndoButton: false)
        }
    }
    
    private func updateDefinitionLabel(card: Card) {
        studyingButton.setTitle(card.listName(), forState: .Normal)
        studyingButton.setTitleColor(card.listColor(), forState: .Normal)
        //        addRemoveButton.setButtonType(card.suspended.boolValue)
//        definitionLabel.font = UIFont(name: Globals.JapaneseFont, size: 28)
//        definitionLabel.text = card.kanji
//        definitionLabel.textColor = card.pitchAccentColor()//.listColor()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateText()
        setupEdgeReveal()
        setupGestures()
    }
    
    override func addNotifications() {
        super.addNotifications()
        
        Globals.notificationEditCardProperties.addObserver(self, selector: "onEditCard", object: nil)
        
        Globals.notificationSidebarInteract.addObserver(self, selector: "onSidebarInteract", object: nil)
        
        Globals.notificationShowDefinition.addObserver(self, selector: "onNotificationShowDefinition")
    }
    
    func onSidebarInteract() {
        rightEdgeReveal.animateSelf(false)
    }
    
    func onEditCard() {
        if !view.hidden {
            rightEdgeReveal.editCardProperties(viewCard, value: Globals.notificationEditCardProperties.value)
            
            saveContext()
        }
    }
    
    private func setupEdgeReveal() {
        rightEdgeReveal = EdgeReveal(
            parent: view,
            revealType: .Right,
            swipeAreaWidth: 0,
            autoHandlePanEvent: false,
            maxYTravel: 60,
            onUpdate: {(offset: CGFloat) -> () in
                self.outputText.frame.origin.x = -offset
                self.addRemoveSidebar.frame.origin.x = Globals.screenSize.width - offset
                self.propertiesSidebar.animate(offset)
            },
            setVisible: {(isVisible: Bool) -> () in
                self.addRemoveSidebar.hidden = !isVisible
                if !isVisible {
                    if let card = self.viewCard {
                        self.propertiesSidebar.updateContents(card, showUndoButton: false)
                        self.updateDefinitionLabel(card)
                    }
                }
        })
        
//        leftEdgeReveal = EdgeReveal(
//            parent: view,
//            revealType: .Left,
//            onUpdate: {(offset: CGFloat) -> () in
//                self.outputText.frame.origin.x = offset
//            },
//            setVisible: {(isVisible: Bool) -> () in
//        })
    }

//    @IBAction func onAddRemoveButtonTouch(sender: AnyObject) {
//        if let viewCard = viewCard {
//            viewCard.suspended = !viewCard.suspended.boolValue
//            
//            addRemoveButton.onInteract()
//            updateButtonState(viewCard)
//            
//            saveContext()
//        }
//    }
    
    func setupGestures() {
        var tapGesture = UITapGestureRecognizer(target: self, action: "respondToTapGesture:")
        self.view.addGestureRecognizer(tapGesture)
        var panGesture = UIPanGestureRecognizer(target: self, action: "respondToPanGesture:")
        panGesture.delegate = self
        self.view.addGestureRecognizer(panGesture)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
        return true
    }
    
    func onNotificationShowDefinition() {
        updateText()
    }
    
    func respondToPanGesture(gesture: UIPanGestureRecognizer) {
        rightEdgeReveal.respondToPanGesture(gesture)
//        switch gesture.state {
//        case .Changed:
//            println(gesture.translationInView(self.view))
//        default:
//            break
//        }
    }
    
    func respondToTapGesture(gesture: UIGestureRecognizer) {
        var tapLocation = gesture.locationInView(self.view)
        
        if Globals.notificationShowDefinition.value != "" && CGRectContainsPoint(self.view.layer.presentationLayer().frame, tapLocation) {
            Globals.notificationShowDefinition.postNotification("")
        }
    }
}