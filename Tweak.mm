#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

// =====================================================
// Roblox Offsets - Version: version-80c7b8e578f241ff
// =====================================================
namespace offsets {
    inline constexpr uintptr_t ScriptContext = 0x3F0;
    inline constexpr uintptr_t LocalPlayer = 0x130;
    inline constexpr uintptr_t Name = 0xB0;
    inline constexpr uintptr_t Parent = 0x68;
    inline constexpr uintptr_t Children = 0x70;
    inline constexpr uintptr_t Workspace = 0x178;
    inline constexpr uintptr_t FakeDataModelPointer = 0x7C75728;
    inline constexpr uintptr_t FakeDataModelToDataModel = 0x1C0;
    inline constexpr uintptr_t GameLoaded = 0x630;
    inline constexpr uintptr_t PlaceId = 0x198;
}

// =====================================================
// Lua C API - Complete Implementation
// =====================================================
typedef struct lua_State lua_State;
typedef int (*lua_CFunction)(lua_State *L);
typedef void *(*lua_Alloc)(void *ud, void *ptr, size_t osize, size_t nsize);
typedef const char *(*lua_Reader)(lua_State *L, void *data, size_t *size);
typedef int (*lua_Writer)(lua_State *L, const void *p, size_t sz, void *ud);
typedef double lua_Number;
typedef ptrdiff_t lua_Integer;

// Lua State manipulation
typedef lua_State *(*lua_newstate_t)(lua_Alloc f, void *ud);
typedef void (*lua_close_t)(lua_State *L);
typedef lua_State *(*lua_newthread_t)(lua_State *L);
typedef lua_CFunction (*lua_atpanic_t)(lua_State *L, lua_CFunction panicf);

// Basic stack manipulation
typedef int (*lua_gettop_t)(lua_State *L);
typedef void (*lua_settop_t)(lua_State *L, int idx);
typedef void (*lua_pushvalue_t)(lua_State *L, int idx);
typedef void (*lua_remove_t)(lua_State *L, int idx);
typedef void (*lua_insert_t)(lua_State *L, int idx);
typedef void (*lua_replace_t)(lua_State *L, int idx);
typedef int (*lua_checkstack_t)(lua_State *L, int sz);
typedef void (*lua_xmove_t)(lua_State *from, lua_State *to, int n);

// Access functions (stack -> C)
typedef int (*lua_isnumber_t)(lua_State *L, int idx);
typedef int (*lua_isstring_t)(lua_State *L, int idx);
typedef int (*lua_iscfunction_t)(lua_State *L, int idx);
typedef int (*lua_isuserdata_t)(lua_State *L, int idx);
typedef int (*lua_type_t)(lua_State *L, int idx);
typedef const char *(*lua_typename_t)(lua_State *L, int tp);

typedef int (*lua_equal_t)(lua_State *L, int idx1, int idx2);
typedef int (*lua_rawequal_t)(lua_State *L, int idx1, int idx2);
typedef int (*lua_lessthan_t)(lua_State *L, int idx1, int idx2);

typedef lua_Number (*lua_tonumber_t)(lua_State *L, int idx);
typedef lua_Integer (*lua_tointeger_t)(lua_State *L, int idx);
typedef int (*lua_toboolean_t)(lua_State *L, int idx);
typedef const char *(*lua_tolstring_t)(lua_State *L, int idx, size_t *len);
typedef size_t (*lua_objlen_t)(lua_State *L, int idx);
typedef lua_CFunction (*lua_tocfunction_t)(lua_State *L, int idx);
typedef void *(*lua_touserdata_t)(lua_State *L, int idx);
typedef lua_State *(*lua_tothread_t)(lua_State *L, int idx);
typedef const void *(*lua_topointer_t)(lua_State *L, int idx);

// Push functions (C -> stack)
typedef void (*lua_pushnil_t)(lua_State *L);
typedef void (*lua_pushnumber_t)(lua_State *L, lua_Number n);
typedef void (*lua_pushinteger_t)(lua_State *L, lua_Integer n);
typedef void (*lua_pushlstring_t)(lua_State *L, const char *s, size_t l);
typedef void (*lua_pushstring_t)(lua_State *L, const char *s);
typedef void (*lua_pushcclosure_t)(lua_State *L, lua_CFunction fn, int n);
typedef void (*lua_pushboolean_t)(lua_State *L, int b);
typedef void (*lua_pushlightuserdata_t)(lua_State *L, void *p);
typedef int (*lua_pushthread_t)(lua_State *L);

// Get functions (Lua -> stack)
typedef void (*lua_gettable_t)(lua_State *L, int idx);
typedef void (*lua_getfield_t)(lua_State *L, int idx, const char *k);
typedef void (*lua_rawget_t)(lua_State *L, int idx);
typedef void (*lua_rawgeti_t)(lua_State *L, int idx, int n);
typedef void (*lua_createtable_t)(lua_State *L, int narr, int nrec);
typedef void *(*lua_newuserdata_t)(lua_State *L, size_t sz);
typedef int (*lua_getmetatable_t)(lua_State *L, int objindex);
typedef void (*lua_getfenv_t)(lua_State *L, int idx);

// Set functions (stack -> Lua)
typedef void (*lua_settable_t)(lua_State *L, int idx);
typedef void (*lua_setfield_t)(lua_State *L, int idx, const char *k);
typedef void (*lua_rawset_t)(lua_State *L, int idx);
typedef void (*lua_rawseti_t)(lua_State *L, int idx, int n);
typedef int (*lua_setmetatable_t)(lua_State *L, int objindex);
typedef int (*lua_setfenv_t)(lua_State *L, int idx);

// Load and call functions (load and run Lua code)
typedef void (*lua_call_t)(lua_State *L, int nargs, int nresults);
typedef int (*lua_pcall_t)(lua_State *L, int nargs, int nresults, int errfunc);
typedef int (*lua_cpcall_t)(lua_State *L, lua_CFunction func, void *ud);
typedef int (*lua_load_t)(lua_State *L, lua_Reader reader, void *dt, const char *chunkname);
typedef int (*lua_dump_t)(lua_State *L, lua_Writer writer, void *data);

// Coroutine functions
typedef int (*lua_yield_t)(lua_State *L, int nresults);
typedef int (*lua_resume_t)(lua_State *L, int narg);
typedef int (*lua_status_t)(lua_State *L);

// Garbage collection
typedef int (*lua_gc_t)(lua_State *L, int what, int data);

// Miscellaneous functions
typedef int (*lua_error_t)(lua_State *L);
typedef int (*lua_next_t)(lua_State *L, int idx);
typedef void (*lua_concat_t)(lua_State *L, int n);

// Auxiliary library
typedef int (*luaL_loadstring_t)(lua_State *L, const char *s);
typedef int (*luaL_loadbuffer_t)(lua_State *L, const char *buff, size_t sz, const char *name);
typedef int (*luaL_loadfile_t)(lua_State *L, const char *filename);
typedef void (*luaL_openlibs_t)(lua_State *L);
typedef int (*luaL_newmetatable_t)(lua_State *L, const char *tname);
typedef void *(*luaL_checkudata_t)(lua_State *L, int ud, const char *tname);
typedef void (*luaL_where_t)(lua_State *L, int lvl);
typedef int (*luaL_error_t)(lua_State *L, const char *fmt, ...);
typedef int (*luaL_checkoption_t)(lua_State *L, int narg, const char *def, const char *const lst[]);
typedef int (*luaL_ref_t)(lua_State *L, int t);
typedef void (*luaL_unref_t)(lua_State *L, int t, int ref);
typedef int (*luaL_getmetafield_t)(lua_State *L, int obj, const char *e);
typedef void (*luaL_checkstack_t)(lua_State *L, int sz, const char *msg);
typedef void (*luaL_checktype_t)(lua_State *L, int narg, int t);
typedef void (*luaL_checkany_t)(lua_State *L, int narg);

// Advanced functions
typedef void (*lua_getglobal_t)(lua_State *L, const char *name);
typedef void (*lua_setglobal_t)(lua_State *L, const char *name);
typedef void (*lua_getregistry_t)(lua_State *L);
typedef int (*lua_getinfo_t)(lua_State *L, const char *what, void *ar);

// Function pointers - Core
static lua_gettop_t lua_gettop = NULL;
static lua_settop_t lua_settop = NULL;
static lua_pushvalue_t lua_pushvalue = NULL;
static lua_type_t lua_type = NULL;
static lua_typename_t lua_typename = NULL;

// Function pointers - Type checking
static lua_isnumber_t lua_isnumber = NULL;
static lua_isstring_t lua_isstring = NULL;
static lua_iscfunction_t lua_iscfunction = NULL;

// Function pointers - To C
static lua_tonumber_t lua_tonumber = NULL;
static lua_tointeger_t lua_tointeger = NULL;
static lua_toboolean_t lua_toboolean = NULL;
static lua_tolstring_t lua_tolstring = NULL;
static lua_tocfunction_t lua_tocfunction = NULL;

// Function pointers - Push
static lua_pushnil_t lua_pushnil = NULL;
static lua_pushnumber_t lua_pushnumber = NULL;
static lua_pushinteger_t lua_pushinteger = NULL;
static lua_pushlstring_t lua_pushlstring = NULL;
static lua_pushstring_t lua_pushstring = NULL;
static lua_pushcclosure_t lua_pushcclosure = NULL;
static lua_pushboolean_t lua_pushboolean = NULL;
static lua_pushlightuserdata_t lua_pushlightuserdata = NULL;

// Function pointers - Get/Set
static lua_gettable_t lua_gettable = NULL;
static lua_getfield_t lua_getfield = NULL;
static lua_rawget_t lua_rawget = NULL;
static lua_rawgeti_t lua_rawgeti = NULL;
static lua_createtable_t lua_createtable = NULL;
static lua_newuserdata_t lua_newuserdata = NULL;
static lua_getmetatable_t lua_getmetatable = NULL;
static lua_settable_t lua_settable = NULL;
static lua_setfield_t lua_setfield = NULL;
static lua_rawset_t lua_rawset = NULL;
static lua_rawseti_t lua_rawseti = NULL;
static lua_setmetatable_t lua_setmetatable = NULL;

// Function pointers - Load/Call
static lua_call_t lua_call = NULL;
static lua_pcall_t lua_pcall = NULL;
static lua_load_t lua_load = NULL;

// Function pointers - Misc
static lua_error_t lua_error = NULL;
static lua_next_t lua_next = NULL;
static lua_concat_t lua_concat = NULL;
static lua_getglobal_t lua_getglobal = NULL;
static lua_setglobal_t lua_setglobal = NULL;

// Function pointers - Auxiliary
static luaL_loadstring_t luaL_loadstring = NULL;
static luaL_loadbuffer_t luaL_loadbuffer = NULL;
static luaL_openlibs_t luaL_openlibs = NULL;
static luaL_newmetatable_t luaL_newmetatable = NULL;
static luaL_ref_t luaL_ref = NULL;
static luaL_unref_t luaL_unref = NULL;

// Global state
static lua_State *g_LuaState = NULL;
static uintptr_t g_BaseAddress = 0;
static WKWebView *g_WebView = NULL;

// =====================================================
// Utility Functions
// =====================================================

uintptr_t getBaseAddress() {
    if (g_BaseAddress != 0) return g_BaseAddress;
    
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, "RobloxPlayer") || strstr(name, "Roblox")) {
            const struct mach_header *header = _dyld_get_image_header(i);
            g_BaseAddress = (uintptr_t)header;
            NSLog(@"[Executor] ✓ Base: 0x%lx", g_BaseAddress);
            return g_BaseAddress;
        }
    }
    return 0;
}

uintptr_t getDataModel() {
    uintptr_t base = getBaseAddress();
    if (!base) return 0;
    
    @try {
        uintptr_t fakePtr = *(uintptr_t*)(base + offsets::FakeDataModelPointer);
        if (fakePtr) {
            uintptr_t dm = *(uintptr_t*)(fakePtr + offsets::FakeDataModelToDataModel);
            if (dm) return dm;
        }
    } @catch (NSException *e) {}
    return 0;
}

lua_State* getScriptContext() {
    uintptr_t dm = getDataModel();
    if (!dm) return NULL;
    
    @try {
        uintptr_t sc = *(uintptr_t*)(dm + offsets::ScriptContext);
        if (!sc) return NULL;
        
        uintptr_t offsets[] = {0x140, 0x138, 0x148, 0x150, 0x130, 0x158, 0x160};
        for (int i = 0; i < 7; i++) {
            lua_State *L = *(lua_State**)(sc + offsets[i]);
            if (L && (uintptr_t)L > 0x100000000) {
                NSLog(@"[Executor] ✓ State at +0x%lx: %p", offsets[i], L);
                return L;
            }
        }
    } @catch (NSException *e) {}
    return NULL;
}

// =====================================================
// Enhanced Lua Execution with Full Support
// =====================================================

void sendToWebView(NSString *type, NSString *msg) {
    if (!g_WebView) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *clean = [[msg 
            stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]
            stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
        NSString *js = [NSString stringWithFormat:@"window.show%@('%@');", type, clean];
        [g_WebView evaluateJavaScript:js completionHandler:nil];
    });
}

// Setup global environment with common functions
void setupGlobalEnvironment(lua_State *L) {
    if (!L || !lua_pushstring || !lua_setglobal) return;
    
    // Make sure all standard libraries are loaded
    if (luaL_openlibs) {
        luaL_openlibs(L);
    }
    
    // Setup common globals that might be missing
    @try {
        // Create a safer print function
        const char *safePrint = R"(
            local oldprint = print
            function print(...)
                local args = {...}
                local str = ""
                for i, v in ipairs(args) do
                    str = str .. tostring(v)
                    if i < #args then str = str .. "\t" end
                end
                oldprint(str)
                return str
            end
        )";
        
        if (luaL_loadstring(L, safePrint) == 0) {
            lua_pcall(L, 0, 0, 0);
        }
        
        // Setup workspace shortcut
        const char *workspaceShortcut = R"(
            workspace = game:GetService("Workspace")
            players = game:GetService("Players")
            localPlayer = players.LocalPlayer
        )";
        
        if (luaL_loadstring(L, workspaceShortcut) == 0) {
            lua_pcall(L, 0, 0, 0);
        }
        
    } @catch (NSException *e) {
        NSLog(@"[Executor] Exception in setupGlobalEnvironment: %@", e);
    }
}

void executeLuaScript(NSString *script) {
    @try {
        if (!g_LuaState) {
            g_LuaState = getScriptContext();
            if (g_LuaState) {
                setupGlobalEnvironment(g_LuaState);
            }
        }
        
        if (!g_LuaState || !luaL_loadstring || !lua_pcall) {
            sendToWebView(@"Error", @"Lua not ready");
            return;
        }
        
        const char *code = [script UTF8String];
        int top = lua_gettop ? lua_gettop(g_LuaState) : 0;
        
        // Try to load the script
        int loadResult = luaL_loadstring(g_LuaState, code);
        
        if (loadResult != 0) {
            const char *err = lua_tolstring(g_LuaState, -1, NULL);
            NSString *errStr = [NSString stringWithUTF8String:err ?: "Load error"];
            NSLog(@"[Executor] Load error: %@", errStr);
            
            if (lua_settop) lua_settop(g_LuaState, top);
            sendToWebView(@"Error", errStr);
            return;
        }
        
        // Execute with error handler
        int execResult = lua_pcall(g_LuaState, 0, 0, 0);
        
        if (execResult != 0) {
            const char *err = lua_tolstring(g_LuaState, -1, NULL);
            NSString *errStr = [NSString stringWithUTF8String:err ?: "Execution error"];
            NSLog(@"[Executor] Exec error: %@", errStr);
            
            if (lua_settop) lua_settop(g_LuaState, top);
            sendToWebView(@"Error", errStr);
            return;
        }
        
        NSLog(@"[Executor] ✓ Success");
        sendToWebView(@"Success", @"Executed");
        
        if (lua_settop) lua_settop(g_LuaState, top);
        
    } @catch (NSException *e) {
        NSLog(@"[Executor] Exception: %@", e);
        sendToWebView(@"Error", e.reason ?: @"Unknown error");
    }
}

// =====================================================
// WebView Handler
// =====================================================

@interface ScriptMessageHandler : NSObject <WKScriptMessageHandler>
@end

@implementation ScriptMessageHandler

- (void)userContentController:(WKUserContentController *)controller 
      didReceiveScriptMessage:(WKScriptMessage *)message {
    
    if ([message.name isEqualToString:@"execute"]) {
        if ([message.body isKindOfClass:[NSString class]]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                executeLuaScript((NSString *)message.body);
            });
        }
    }
    else if ([message.name isEqualToString:@"inject"]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            g_LuaState = getScriptContext();
            if (g_LuaState) {
                setupGlobalEnvironment(g_LuaState);
                sendToWebView(@"Success", @"Injected!");
            } else {
                sendToWebView(@"Error", @"Injection failed");
            }
        });
    }
    else if ([message.name isEqualToString:@"getStatus"]) {
        uintptr_t dm = getDataModel();
        bool loaded = dm ? *(bool*)(dm + offsets::GameLoaded) : false;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *js = [NSString stringWithFormat:
                @"window.updateStatus({ready:%@,state:'%p',loaded:%@});",
                g_LuaState ? @"true" : @"false", g_LuaState, loaded ? @"true" : @"false"];
            [g_WebView evaluateJavaScript:js completionHandler:nil];
        });
    }
}

@end

// =====================================================
// Draggable WebView
// =====================================================

@interface DraggableWebView : WKWebView
@property (nonatomic, assign) CGPoint lastLocation;
@end

@implementation DraggableWebView
- (void)handlePan:(UIPanGestureRecognizer *)r {
    CGPoint t = [r translationInView:self.superview];
    if (r.state == UIGestureRecognizerStateBegan) self.lastLocation = self.center;
    self.center = CGPointMake(self.lastLocation.x + t.x, self.lastLocation.y + t.y);
}
@end

// =====================================================
// WebView Setup with Enhanced UI
// =====================================================

void setupWebView() {
    dispatch_async(dispatch_get_main_queue(), ^{
        WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
        WKUserContentController *ctrl = [[WKUserContentController alloc] init];
        
        ScriptMessageHandler *h = [[ScriptMessageHandler alloc] init];
        [ctrl addScriptMessageHandler:h name:@"execute"];
        [ctrl addScriptMessageHandler:h name:@"inject"];
        [ctrl addScriptMessageHandler:h name:@"getStatus"];
        
        cfg.userContentController = ctrl;
        cfg.preferences.javaScriptEnabled = YES;
        
        CGRect s = [[UIScreen mainScreen] bounds];
        CGRect f = CGRectMake(10, 80, s.size.width - 20, s.size.height * 0.65);
        
        g_WebView = [[DraggableWebView alloc] initWithFrame:f configuration:cfg];
        g_WebView.backgroundColor = [UIColor colorWithWhite:0.02 alpha:0.98];
        g_WebView.layer.cornerRadius = 25;
        g_WebView.layer.masksToBounds = YES;
        g_WebView.layer.borderWidth = 3;
        g_WebView.layer.borderColor = [UIColor colorWithRed:0 green:1 blue:0.53 alpha:0.6].CGColor;
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] 
            initWithTarget:g_WebView action:@selector(handlePan:)];
        [g_WebView addGestureRecognizer:pan];
        
        NSString *html = @R"HTML(
<!DOCTYPE html>
<html><head>
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system;background:#050505;color:#fff;padding:15px;overflow:hidden}
.header{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;padding-bottom:10px;border-bottom:3px solid #00ff88}
h1{font-size:22px;color:#00ff88;font-weight:800;text-shadow:0 0 10px #00ff8844}
.status{display:flex;align-items:center;gap:8px;font-size:11px;font-weight:600}
.dot{width:12px;height:12px;border-radius:50%;background:#ff4444;animation:pulse 1.5s infinite;box-shadow:0 0 8px currentColor}
.dot.ready{background:#00ff88}
@keyframes pulse{0%,100%{opacity:1;transform:scale(1)}50%{opacity:0.6;transform:scale(0.9)}}
textarea{width:100%;height:270px;background:#0f0f0f;color:#00ff88;border:2px solid #1a1a1a;border-radius:15px;padding:12px;font-family:Menlo,Monaco,monospace;font-size:13px;resize:none;outline:none;box-shadow:inset 0 2px 8px #00000088}
textarea:focus{border-color:#00ff88;box-shadow:inset 0 2px 8px #00000088,0 0 15px #00ff8833}
.btns{display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-top:12px}
button{padding:14px;background:linear-gradient(135deg,#00ff88,#00cc6f);color:#000;border:none;border-radius:12px;font-weight:800;font-size:13px;cursor:pointer;transition:all .15s;box-shadow:0 4px 12px #00ff8833;text-transform:uppercase;letter-spacing:0.5px}
button:active{transform:translateY(2px);box-shadow:0 2px 6px #00ff8833}
.btn-clear{background:linear-gradient(135deg,#ff4444,#cc0000);box-shadow:0 4px 12px #ff444433}
.btn-inject{background:linear-gradient(135deg,#4488ff,#0044cc);box-shadow:0 4px 12px #4488ff33}
.console{background:#000;border:2px solid#1a1a1a;border-radius:12px;padding:10px;margin-top:12px;height:85px;overflow-y:auto;font-size:11px;font-family:monospace;box-shadow:inset 0 2px 6px #00000088}
.console div{padding:3px 0;border-bottom:1px solid #0a0a0a}
.success{color:#00ff88;font-weight:600}
.error{color:#ff4444;font-weight:600}
.info{color:#4488ff}
.scripts{display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-top:8px}
.script-btn{padding:8px;background:#1a1a1a;border:1px solid #333;border-radius:8px;color:#00ff88;font-size:11px;font-weight:600}
</style>
</head><body>
<div class="header">
<h1>⚡ ROBLOX EXECUTOR</h1>
<div class="status">
<div class="dot" id="dot"></div>
<span id="status">INIT</span>
</div>
</div>
<textarea id="code" placeholder="-- Full Lua Support Enabled&#10;-- Examples:&#10;&#10;game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 100&#10;&#10;workspace.Gravity = 50&#10;&#10;for _,v in pairs(game.Players:GetPlayers()) do&#10;    print(v.Name)&#10;end"></textarea>
<div class="btns">
<button onclick="exec()">▶ EXEC</button>
<button class="btn-clear" onclick="clr()">🗑 CLEAR</button>
<button class="btn-inject" onclick="inj()">💉 INJECT</button>
</div>
<div class="scripts">
<button class="script-btn" onclick="quick('game.Players.LocalPlayer.Character.Humanoid.WalkSpeed=100')">⚡ SPEED</button>
<button class="script-btn" onclick="quick('game.Players.LocalPlayer.Character.Humanoid.JumpPower=200')">🦘 JUMP</button>
<button class="script-btn" onclick="quick('workspace.Gravity=50')">🌙 LOW GRAV</button>
<button class="script-btn" onclick="quick('game.Players.LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Flying)')">🦅 FLY</button>
</div>
<div class="console" id="con"></div>
<script>
function exec(){
const c=document.getElementById('code').value.trim();
if(!c){showError('Empty script');return}
window.webkit.messageHandlers.execute.postMessage(c)
}
function clr(){document.getElementById('code').value='';document.getElementById('con').innerHTML=''}
function inj(){window.webkit.messageHandlers.inject.postMessage('')}
function quick(s){window.webkit.messageHandlers.execute.postMessage(s)}
function log(m,t){
const c=document.getElementById('con');
const time=new Date().toLocaleTimeString();
c.innerHTML+=`<div class="${t}">[${time}] ${m}</div>`;
c.scrollTop=c.scrollHeight
}
function showError(m){log('❌ '+m,'error')}
function showSuccess(m){log('✓ '+m,'success')}
function showInfo(m){log('ℹ '+m,'info')}
function updateStatus(d){
const dot=document.getElementById('dot');
const txt=document.getElementById('status');
if(d.ready&&d.loaded){
dot.className='dot ready';
txt.textContent='READY'
}else if(d.ready){
dot.className='dot';
txt.textContent='LOADING'
}else{
dot.className='dot';
txt.textContent='WAIT'
}
}
setInterval(()=>{window.webkit.messageHandlers.getStatus.postMessage('')},2000);
setTimeout(()=>{window.webkit.messageHandlers.getStatus.postMessage('')},500)
</script>
</body></html>
)HTML";
        
        [g_WebView loadHTMLString:html baseURL:nil];
        
        UIWindow *w = [[UIApplication sharedApplication] windows].firstObject 
                   ?: [[UIApplication sharedApplication] keyWindow];
        if (w) {
            [w addSubview:g_WebView];
            NSLog(@"[Executor] ✓ UI loaded");
        }
    });
}

// =====================================================
// Initialize All Lua Functions
// =====================================================

void initLuaFunctions() {
    // Try multiple methods to find Lua functions
    void *handle = dlopen(NULL, RTLD_LAZY);
    
    #define LOAD_FUNC(name) name = (name##_t)dlsym(handle, #name); \
        if (!name) name = (name##_t)dlsym(RTLD_DEFAULT, #name)
    
    // Core
    LOAD_FUNC(lua_gettop);
    LOAD_FUNC(lua_settop);
    LOAD_FUNC(lua_pushvalue);
    LOAD_FUNC(lua_type);
    LOAD_FUNC(lua_typename);
    
    // Type checking
    LOAD_FUNC(lua_isnumber);
    LOAD_FUNC(lua_isstring);
    LOAD_FUNC(lua_iscfunction);
    
    // To C
    LOAD_FUNC(lua_tonumber);
    LOAD_FUNC(lua_tointeger);
    LOAD_FUNC(lua_toboolean);
    LOAD_FUNC(lua_tolstring);
    LOAD_FUNC(lua_tocfunction);
    
    // Push
    LOAD_FUNC(lua_pushnil);
    LOAD_FUNC(lua_pushnumber);
    LOAD_FUNC(lua_pushinteger);
    LOAD_FUNC(lua_pushlstring);
    LOAD_FUNC(lua_pushstring);
    LOAD_FUNC(lua_pushcclosure);
    LOAD_FUNC(lua_pushboolean);
    LOAD_FUNC(lua_pushlightuserdata);
    
    // Get/Set
    LOAD_FUNC(lua_gettable);
    LOAD_FUNC(lua_getfield);
    LOAD_FUNC(lua_rawget);
    LOAD_FUNC(lua_rawgeti);
    LOAD_FUNC(lua_createtable);
    LOAD_FUNC(lua_newuserdata);
    LOAD_FUNC(lua_getmetatable);
    LOAD_FUNC(lua_settable);
    LOAD_FUNC(lua_setfield);
    LOAD_FUNC(lua_rawset);
    LOAD_FUNC(lua_rawseti);
    LOAD_FUNC(lua_setmetatable);
    
    // Load/Call
    LOAD_FUNC(lua_call);
    LOAD_FUNC(lua_pcall);
    LOAD_FUNC(lua_load);
    
    // Misc
    LOAD_FUNC(lua_error);
    LOAD_FUNC(lua_next);
    LOAD_FUNC(lua_concat);
    LOAD_FUNC(lua_getglobal);
    LOAD_FUNC(lua_setglobal);
    
    // Auxiliary
    LOAD_FUNC(luaL_loadstring);
    LOAD_FUNC(luaL_loadbuffer);
    LOAD_FUNC(luaL_openlibs);
    LOAD_FUNC(luaL_newmetatable);
    LOAD_FUNC(luaL_ref);
    LOAD_FUNC(luaL_unref);
    
    NSLog(@"[Executor] Lua funcs: loadstring=%p pcall=%p settop=%p", 
          luaL_loadstring, lua_pcall, lua_settop);
}

// =====================================================
// Constructor
// =====================================================

__attribute__((constructor))
static void initialize() {
    NSLog(@"========================================");
    NSLog(@"[Executor] 🚀 FULL LUA SUPPORT LOADED");
    NSLog(@"========================================");
    
    getBaseAddress();
    initLuaFunctions();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), 
        dispatch_get_main_queue(), ^{
        setupWebView();
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(2);
            g_LuaState = getScriptContext();
            if (g_LuaState) {
                setupGlobalEnvironment(g_LuaState);
                NSLog(@"[Executor] ✓ Ready!");
            }
        });
    });
}
