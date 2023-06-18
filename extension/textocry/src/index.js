import Tesseract from 'tesseract.js';
import { v4 as uuidv4 } from 'uuid';
import firebase from 'firebase/compat/app';
import 'firebase/compat/auth';

const firebaseConfig = {
    apiKey: "AIzaSyCJv99y-SQANQ6w3xo-ovK_R5zd50AiIBI",
    authDomain: "fire-alarm-system-2a104.firebaseapp.com",
    databaseURL: "https://fire-alarm-system-2a104-default-rtdb.firebaseio.com",
    projectId: "fire-alarm-system-2a104",
    storageBucket: "fire-alarm-system-2a104.appspot.com",
    messagingSenderId: "905982905609",
    appId: "1:905982905609:web:5983a249927af72e2f97d8",
    measurementId: "G-5567C7YB5S"
};
  
firebase.initializeApp(firebaseConfig);

function handleFirebaseAuth() {
    const provider = new firebase.auth.GoogleAuthProvider();
    firebase.auth().signInWithPopup(provider)
        .then((result) => {
        // User signed in successfully
        const user = result.user;
        chrome.storage.sync.set({ uid: user.uid })
    })
    .catch((error) => {
        console.error(`Error signing in: ${error}`);
    });
}

function updateDateToFirebase(data) {
    chrome.storage.sync.get((config) => {
        const docId = config.documentId
        const uid = config.uid
        const url =`https://fire-alarm-system-2a104-default-rtdb.firebaseio.com/notes/${docId}`;
        if(config.userset === undefined) {
            fetch(
                url+'.json', 
                {
                    method: "PUT",
                    body: JSON.stringify(
                        {
                            data : {
                                ramdom:{
                                    insert: data,
                                }
                            },
                            info : {
                                created_at : Date.now(),
                                allowed_users:[
                                    uid
                                ]
                            }
                        }
                    ),
                    headers: {
                        "Content-type": "application/json; charset=UTF-8"
                    }
                }).then((_) =>{
                    chrome.storage.sync.set({ userset: true })
                })
        }else{
            fetch(
                url+'/data.json', 
                {
                    method: "POST",
                    body: JSON.stringify(
                        {
                           insert:data
                        }
                    ),
                    headers: {
                        "Content-type": "application/json; charset=UTF-8"
                    }
                })
        }
    })
}

function handleChromeStorageSetting() {
    chrome.storage.sync.get((config) => {
        chrome.storage.sync.set({ documentId: uuidv4() })
        chrome.storage.sync.set({ userset: undefined })
        if (!config.method) {
            chrome.storage.sync.set({ method: 'crop' })
        }
        if (!config.format) {
            chrome.storage.sync.set({ format: 'png' })
        }
        if (config.dpr === undefined) {
            chrome.storage.sync.set({ dpr: true })
        }
        if(config.uid === undefined) {
            handleFirebaseAuth()
        }
        // this will create a new documnet for each new tab
        
    })
}

function handleOnActionInvoked() {
    //1. Called when we click the icon in the tools
    chrome.browserAction.onClicked.addListener((tab) => {
        inject(tab)
    })

    // 2. Called when the screen-shot action is invoked
    chrome.commands.onCommand.addListener((command) => {
        if (command === 'take-screenshot') {
            chrome.tabs.getSelected(null, (tab) => {
                inject(tab)
            })
        }
    })
}


function handleEvents() {
    chrome.runtime.onMessage.addListener((req, sender, res) => {
        if (req.message === 'capture') {
            chrome.storage.sync.get((config) => {
    
                chrome.tabs.getSelected(null, (tab) => {
    
                    chrome.tabs.captureVisibleTab(tab.windowId, { format: config.format }, (image) => {
                        crop(image, req.area, req.dpr, config.dpr, config.format, tab,(cropped) => {
                            res({ message: 'extracted' })
                        })
                    })
                })
            })
        }
        else if (req.message === 'active') {
            if (req.active) {
                chrome.storage.sync.get((config) => {
                    if (config.method === 'crop') {
                        chrome.browserAction.setTitle({ tabId: sender.tab.id, title: 'Select region' })
                        chrome.browserAction.setBadgeText({ tabId: sender.tab.id, text: '⯐' })
                    }
                })
            }
            else {
                chrome.browserAction.setTitle({ tabId: sender.tab.id, title: 'Copy text from image' })
                chrome.browserAction.setBadgeText({ tabId: sender.tab.id, text: '' })
            }
        }
        return true
    })
}


function inject(tab) {
    chrome.tabs.sendMessage(tab.id, { message: 'init' }, (res) => {
        if (res) {
            clearTimeout(timeout)
        }
    })

    var timeout = setTimeout(() => {
        chrome.tabs.insertCSS(tab.id, { file: 'vendor/jquery.Jcrop.min.css', runAt: 'document_start' })
        chrome.tabs.insertCSS(tab.id, { file: 'css/content.css', runAt: 'document_start' })

        chrome.tabs.executeScript(tab.id, { file: 'vendor/jquery.min.js', runAt: 'document_start' })
        chrome.tabs.executeScript(tab.id, { file: 'vendor/jquery.Jcrop.min.js', runAt: 'document_start' })
        chrome.tabs.executeScript(tab.id, { file: 'content/content.js', runAt: 'document_start' })

        setTimeout(() => {
            chrome.tabs.sendMessage(tab.id, { message: 'init' })
        }, 100)
    }, 100)
}


function crop(image, area, dpr, preserve, format, tab, done) {
    var top = area.y * dpr
    var left = area.x * dpr
    var width = area.w * dpr
    var height = area.h * dpr
    var w = (dpr !== 1 && preserve) ? width : area.w
    var h = (dpr !== 1 && preserve) ? height : area.h

    var canvas = null
    if (!canvas) {
        canvas = document.createElement('canvas')
        document.body.appendChild(canvas)
    }
    canvas.width = w
    canvas.height = h

    var img = new Image()
    img.onload = () => {
        var context = canvas.getContext('2d')
        context.drawImage(img,
            left, top,
            width, height,
            0, 0,
            w, h
        )

        var cropped = canvas.toDataURL(`image/${format}`)

        Tesseract.recognize(cropped, {
            lang: 'eng'
        })
            .then(function (result) {
                // Send post request to firebase
                updateDateToFirebase(result.text);
                document.oncopy = function (event) {
                    event.clipboardData.setData('text/plain', result.text);
                    event.preventDefault();
                };
                document.execCommand("copy", false, null);
                chrome.tabs.sendMessage(tab.id, { message: 'loaded' }, (res) => {
                    if (res) {
                        clearTimeout(timeout)
                    }
                })
            });


        done(cropped)
    };
    img.src = image
}


// The starting point of the code
handleChromeStorageSetting()
handleOnActionInvoked()
handleEvents()