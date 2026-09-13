
const muteActionFileName = 'mute';
const deafenActionFileName = 'deafen';

const muteButtonSelector = `
:is(
button.button__67645.enabled__67645.button__201d5.button__67645:has(g[clip-path="url(#__lottie_element_5)"]),
button:has(g[clip-path="url(#__lottie_element_5)"])
)
`;

const deafenButtonSelector = `
:is(
button.button__67645.enabled__67645.button__201d5.button__67645:has(g[clip-path="url(#__lottie_element_42)"]),
button:has(g[clip-path="url(#__lottie_element_42)"])
)
`;

const fs = require('fs');
const path = require('path');
const { BrowserWindow, webContents, app } = require('electron');

try {
    fs.appendFileSync(path.join(__dirname, 'vcc_debug.log'), `[customCode.js] Loaded. __dirname=${__dirname}\n`);
} catch(e) {}

// === Unified Logger ===
const LOG_PREFIX = '[VesktopCustomCommands]';

// Queue for logs before window is ready
let pendingLogs = [];
let windowReady = false;

const sendLogToWindow = (win, level, escapedMessage) => {
    win.webContents.executeJavaScript(`console.${level}("${LOG_PREFIX}", "${escapedMessage}")`).catch(() => {});
};

const logToRenderer = (level, ...args) => {
    const message = args.map(a => typeof a === 'object' ? JSON.stringify(a) : String(a)).join(' ');
    const escapedMessage = message.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n');

    if (!windowReady) {
        pendingLogs.push({ level, escapedMessage });
        return;
    }

    BrowserWindow.getAllWindows().forEach(win => {
        sendLogToWindow(win, level, escapedMessage);
    });
};

const flushPendingLogs = (win) => {
    pendingLogs.forEach(({ level, escapedMessage }) => {
        sendLogToWindow(win, level, escapedMessage);
    });
    pendingLogs = [];
};

// Wait for window to be ready before sending queued logs
app.on('browser-window-created', (event, win) => {
    win.webContents.on('did-finish-load', () => {
        if (!windowReady) {
            windowReady = true;
            flushPendingLogs(win);
        }
    });
});

const logger = {
    log: (...args) => { console.log(LOG_PREFIX, ...args); logToRenderer('log', ...args); },
    info: (...args) => { console.info(LOG_PREFIX, ...args); logToRenderer('info', ...args); },
    warn: (...args) => { console.warn(LOG_PREFIX, ...args); logToRenderer('warn', ...args); },
    error: (...args) => { console.error(LOG_PREFIX, ...args); logToRenderer('error', ...args); }
};

logger.info("Custom code executed from customCode.js");
logger.info("Made with ❤️ by NitramO");

// === Click / Toggle in Renderer ===
const triggerAction = (type) => {
    const isMute = type === 'mute';
    logger.info(`Action: Toggle ${type} triggered`);

    const debugLog = (msg) => {
        try {
            fs.appendFileSync(path.join(__dirname, 'vcc_debug.log'), `[${new Date().toISOString()}] ${msg}\n`);
        } catch (e) {}
    };

    debugLog(`Triggered action: ${type}`);

    const allWcs = typeof webContents.getAllWebContents === 'function' 
        ? webContents.getAllWebContents() 
        : BrowserWindow.getAllWindows().map(w => w.webContents);

    allWcs.forEach((wc, index) => {
        if (wc.isDestroyed()) return;
        const url = wc.getURL ? wc.getURL() : '';
        debugLog(`WebContents ${index} URL: ${url}`);

        wc.executeJavaScript(`
            (function() {
                try {
                    // Strategy 1: Vencord Webpack Voice Module (Direct toggle)
                    if (window.Vencord && window.Vencord.Webpack) {
                        const voiceMod = window.Vencord.Webpack.findByProps("toggleSelfMute");
                        if (voiceMod) {
                            if (${isMute}) {
                                const toggleMute = voiceMod.toggleSelfMute || voiceMod.setSelfMute;
                                if (typeof toggleMute === 'function') {
                                    toggleMute.call(voiceMod);
                                    return 'Toggled mute via Vencord.Webpack';
                                }
                            } else {
                                const toggleDeaf = voiceMod.toggleSelfDeaf || voiceMod.toggleSelfDeafen || voiceMod.setSelfDeaf;
                                if (typeof toggleDeaf === 'function') {
                                    toggleDeaf.call(voiceMod);
                                    return 'Toggled deafen via Vencord.Webpack';
                                }
                            }
                        }
                    }

                    // Strategy 2: Specific aria-label and DOM selectors (Safe - excludes disconnect)
                    const selectors = ${isMute} ? [
                        'button[aria-label*="Mute" i]:not([aria-label*="Disconnect" i])',
                        'button[aria-label*="Unmute" i]:not([aria-label*="Disconnect" i])',
                        'button[aria-label*="Micro" i]:not([aria-label*="Disconnect" i])',
                        'button[aria-label*="Stumm" i]:not([aria-label*="Disconnect" i])',
                        'button:has(g[clip-path*="lottie_element_5"])'
                    ] : [
                        'button[aria-label*="Deafen" i]:not([aria-label*="Disconnect" i])',
                        'button[aria-label*="Undeafen" i]:not([aria-label*="Disconnect" i])',
                        'button[aria-label*="Casque" i]:not([aria-label*="Disconnect" i])',
                        'button[aria-label*="Taub" i]:not([aria-label*="Disconnect" i])',
                        'button:has(g[clip-path*="lottie_element_42"])'
                    ];

                    for (const sel of selectors) {
                        const el = document.querySelector(sel);
                        if (el) {
                            el.click();
                            return 'Clicked element with selector: ' + sel;
                        }
                    }

                    // Strategy 3: Search all buttons in document by label
                    const allButtons = Array.from(document.querySelectorAll('button'));
                    for (const b of allButtons) {
                        const label = (b.getAttribute('aria-label') || '').toLowerCase();
                        if (label.includes('disconnect') || label.includes('hang up') || label.includes('leave')) {
                            continue; // NEVER click disconnect!
                        }
                        if (${isMute} && (label.includes('mute') || label.includes('micro') || label.includes('stumm'))) {
                            b.click();
                            return 'Clicked button with label: ' + label;
                        }
                        if (!${isMute} && (label.includes('deafen') || label.includes('undeafen') || label.includes('casque') || label.includes('taub'))) {
                            b.click();
                            return 'Clicked button with label: ' + label;
                        }
                    }

                    return 'Button not found. Total buttons on page: ' + allButtons.length;
                } catch (err) {
                    return 'Error: ' + err.message;
                }
            })();
        `).then(result => {
            debugLog(`Window ${index}: ${result}`);
            logger.log(`Result: ${result}`);
        }).catch(err => {
            debugLog(`Window ${index} executeJavaScript error: ${err.message}`);
        });
    });
};

// === File Monitor ===
const monitorFile = (filePath, action) => {
    const checkFile = () => {
        fs.stat(filePath, (err, stats) => {
            if (err) return; // File doesn't exist

            if (!stats.isFile()) {
                logger.warn(`Ignored: ${filePath} is not a file`);
                return;
            }

            try {
                fs.appendFileSync(path.join(__dirname, 'vcc_debug.log'), `[customCode.js] Detected file: ${filePath}\n`);
            } catch(e) {}

            logger.log(`File found: ${filePath}`);
            fs.unlink(filePath, (unlinkErr) => {
                if (unlinkErr) {
                    logger.error(`Error deleting file ${filePath}:`, unlinkErr.message);
                    return;
                }
                logger.log(`Deleted file: ${filePath}`);
                action();
            });
        });
    };
    setInterval(checkFile, 350);
};

// === Define paths and actions ===
const muteFilePath = path.join(__dirname, muteActionFileName);
const deafenFilePath = path.join(__dirname, deafenActionFileName);

const muteAction = () => {
    triggerAction('mute');
};

const deafenAction = () => {
    triggerAction('deafen');
};

// === Start monitoring ===
monitorFile(muteFilePath, muteAction);
monitorFile(deafenFilePath, deafenAction);

logger.info('Monitoring of mute and deafen files started.');
