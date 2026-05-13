This branch contains the [patches](https://github.com/minh-ton/reynard-browser/commit/da422357212c43b7c1c019c862fc2e54e6935748) for webpage text selection inside Reynard Browser.

To have native UIKit text selection, the patches rely on the existing UITextInput/UITextInteraction bridge (which is already implemented for text input fields interaction) for the native selection highlights. 

For this approach to work, we need to introduce some new IPDL messages (see the patch for  `dom/ipc/BrowserChild.cpp`), which are responsible for selecting the word at the tapped point, clearing the selection, applying selection range change, and querying geometry updates. As far as I know, these IPDL messages block the calling process until the other side responds, which may result in jank, deadlocks, or performance problems. In reality, through lots of testing, I found the text selection to be slow and buggy, sometimes it would cause the entire browser app to freeze.

And this approach also has another issue. We are drawing the native selection highlight as an overlay on top of the entire webpage, so there is no way to clip or hide these selections when the text become invisible under an element (e.g. a sticky menu or out of the visible part of a scroll view). Gecko has an AccessibleCaret system for touch screens, which has the text selection highlight and handles painted by the engine along with the text frame itself (in `layout/generic/nsTextFrame.cpp` and probably some other CSS files as well), but I made this hidden as of now because it interferes with the native text input field interactions. If I remember correctly WebKit also does this by letting the engine paint the page selection while UIKit provide the menu.

Because of these problems, the patches on this branch is for experimental purposes only and will never be implemented in future releases. Reynard will probably have webpage text selection when I finally figure out a solution that is similar to AccessibleCaret or WebKit's. I really need help on this because it's currently beyond my ability, not to mention that having the UIKit bridge to work properly from iOS 14 to latest is truly a real pain.

<img height="300" src="https://github.com/user-attachments/assets/5d527b9e-7dcb-4591-b7f0-c4c4fba19c3a" />
<img height="300" src="https://github.com/user-attachments/assets/99c35baf-0b46-43be-9810-3c95ed719132" />
