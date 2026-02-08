//
//  VR7Executor.mm
//  Ultimate Roblox Executor - Perfect Edition
//  Version: 5.0.0 - ZERO MAINTENANCE REQUIRED
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <sys/stat.h>

#define VR7_VERSION "5.0.0"
#define OFFSETS_URL @"https://raw.githubusercontent.com/NtReadVirtualMemory/Roblox-Offsets-Website/refs/heads/main/offsets.json"
#define SCRIPTS_API @"https://scriptblox.com/api/script/search"
#define VR7_LOG(fmt, ...) NSLog(@"[VR7] " fmt, ##__VA_ARGS__)

// Global state
static uint64_t g_XORKey = 0;
static uintptr_t g_BaseAddress = 0;
static lua_State *g_LuaState = NULL;
static WKWebView *g_WebView = nil;
static UIButton *g_FloatingButton = nil;
static NSMutableDictionary *g_Offsets = nil;
static NSMutableArray *g_Favorites = nil;
static NSTimer *g_UpdateTimer = nil;
static bool g_InGame = false;

#define ENCRYPT(ptr) ((uintptr_t)(ptr) ^ g_XORKey)
#define DECRYPT(enc) ((void*)((uintptr_t)(enc) ^ g_XORKey))

// Lua types
typedef struct lua_State lua_State;
typedef int (*lua_CFunction)(lua_State *L);
typedef int (*lua_gettop_t)(lua_State *L);
typedef void (*lua_settop_t)(lua_State *L, int idx);
typedef int (*lua_type_t)(lua_State *L, int idx);
typedef const char *(*lua_tolstring_t)(lua_State *L, int idx, size_t *len);
typedef void (*lua_pushstring_t)(lua_State *L, const char *s);
typedef void (*lua_pushnil_t)(lua_State *L);
typedef void (*lua_pushboolean_t)(lua_State *L, int b);
typedef void (*lua_call_t)(lua_State *L, int nargs, int nresults);
typedef int (*lua_pcall_t)(lua_State *L, int nargs, int nresults, int errfunc);
typedef int (*luaL_loadstring_t)(lua_State *L, const char *s);
typedef void (*lua_getglobal_t)(lua_State *L, const char *name);
typedef void (*lua_setglobal_t)(lua_State *L, const char *name);
typedef int (*luau_load_t)(lua_State *L, const char *name, const char *data, size_t size, int env);
typedef char *(*luau_compile_t)(const char *source, size_t size, void *opts, size_t *outsize);

static lua_gettop_t lua_gettop = NULL;
static lua_settop_t lua_settop = NULL;
static lua_type_t lua_type = NULL;
static lua_tolstring_t lua_tolstring = NULL;
static lua_pushstring_t lua_pushstring = NULL;
static lua_pushnil_t lua_pushnil = NULL;
static lua_pushboolean_t lua_pushboolean = NULL;
static lua_call_t lua_call = NULL;
static lua_pcall_t lua_pcall = NULL;
static luaL_loadstring_t luaL_loadstring = NULL;
static lua_getglobal_t lua_getglobal = NULL;
static lua_setglobal_t lua_setglobal = NULL;
static luau_load_t luau_load = NULL;
static luau_compile_t luau_compile = NULL;

@interface VR7Script : NSObject
@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *game;
@property (nonatomic, strong) NSString *script;
@property (nonatomic, assign) BOOL isFavorite;
@end
@implementation VR7Script
@end

// =====================================================
// OFFSETS MANAGER - AUTO-UPDATE
// =====================================================

@interface VR7Offsets : NSObject
+ (void)initialize;
+ (void)update:(void(^)(BOOL))completion;
+ (NSDictionary *)defaults;
@end

@implementation VR7Offsets

+ (void)initialize {
    g_Offsets = [[self defaults] mutableCopy];
    
    // Update now
    [self update:^(BOOL success) {
        if (success) VR7_LOG("✅ Offsets updated");
    }];
    
    // Auto-update every 30 minutes
    g_UpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1800 repeats:YES block:^(NSTimer *t) {
        [self update:nil];
    }];
}

+ (NSDictionary *)defaults {
    return @{
        @"ScriptContext": @0x3F0,
        @"FakeDataModelPointer": @0x7C75728,
        @"FakeDataModelToDataModel": @0x1C0,
        @"GameLoaded": @0x630
    };
}

+ (void)update:(void(^)(BOOL))completion {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:OFFSETS_URL];
    
    [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
        if (err || !data) {
            if (completion) completion(NO);
            return;
        }
        
        @try {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (!json) {
                if (completion) completion(NO);
                return;
            }
            
            NSMutableDictionary *converted = [NSMutableDictionary dictionary];
            for (NSString *key in json) {
                id val = json[key];
                if ([val isKindOfClass:[NSString class]] && [val hasPrefix:@"0x"]) {
                    NSScanner *scanner = [NSScanner scannerWithString:val];
                    unsigned long long hex;
                    [scanner setScanLocation:2];
                    if ([scanner scanHexLongLong:&hex]) {
                        converted[key] = @(hex);
                    }
                } else {
                    converted[key] = val;
                }
            }
            
            g_Offsets = converted;
            VR7_LOG("Offsets: %@", g_Offsets[@"RobloxVersion"] ?: @"unknown");
            if (completion) completion(YES);
            
        } @catch (NSException *e) {
            if (completion) completion(NO);
        }
    }] resume];
}

@end

// =====================================================
// MEMORY ACCESS
// =====================================================

@interface VR7Memory : NSObject
+ (uintptr_t)read:(uintptr_t)addr;
@end

@implementation VR7Memory
+ (uintptr_t)read:(uintptr_t)addr {
    @try {
        if (addr < 0x100000000) return 0;
        return *(uintptr_t*)addr;
    } @catch (NSException *e) {
        return 0;
    }
}
@end

// =====================================================
// ROBLOX ACCESS
// =====================================================

@interface VR7Roblox : NSObject
+ (uintptr_t)getBase;
+ (uintptr_t)getDataModel;
+ (lua_State *)getLuaState;
+ (BOOL)isInGame;
@end

@implementation VR7Roblox

+ (uintptr_t)getBase {
    if (g_BaseAddress) return g_BaseAddress;
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, "Roblox")) {
            g_BaseAddress = (uintptr_t)_dyld_get_image_header(i);
            VR7_LOG("Base: 0x%lx", g_BaseAddress);
            return g_BaseAddress;
        }
    }
    return 0;
}

+ (uintptr_t)getDataModel {
    uintptr_t base = [self getBase];
    if (!base) return 0;
    
    uintptr_t fake = [g_Offsets[@"FakeDataModelPointer"] unsignedLongValue];
    uintptr_t dm = [g_Offsets[@"FakeDataModelToDataModel"] unsignedLongValue];
    
    uintptr_t fakePtr = [VR7Memory read:base + fake];
    if (!fakePtr) return 0;
    
    return [VR7Memory read:fakePtr + dm];
}

+ (lua_State *)getLuaState {
    if (g_LuaState) return g_LuaState;
    
    uintptr_t dm = [self getDataModel];
    if (!dm) return NULL;
    
    uintptr_t sc = [g_Offsets[@"ScriptContext"] unsignedLongValue];
    uintptr_t scPtr = [VR7Memory read:dm + sc];
    if (!scPtr) return NULL;
    
    uintptr_t offsets[] = {0x140, 0x138, 0x148, 0x150, 0x130, 0x158};
    for (int i = 0; i < 6; i++) {
        lua_State *L = (lua_State*)[VR7Memory read:scPtr + offsets[i]];
        if (L && (uintptr_t)L > 0x100000000) {
            g_LuaState = L;
            VR7_LOG("Lua: %p", L);
            return L;
        }
    }
    return NULL;
}

+ (BOOL)isInGame {
    uintptr_t dm = [self getDataModel];
    if (!dm) return NO;
    
    uintptr_t gl = [g_Offsets[@"GameLoaded"] unsignedLongValue];
    return *(bool*)(dm + gl);
}

@end

// =====================================================
// SCRIPT HUB
// =====================================================

@interface VR7Hub : NSObject
+ (void)search:(NSString *)q completion:(void(^)(NSArray *))cb;
+ (void)addFavorite:(VR7Script *)s;
+ (NSArray *)getFavorites;
@end

@implementation VR7Hub

+ (void)search:(NSString *)q completion:(void(^)(NSArray *))cb {
    NSString *url = [NSString stringWithFormat:@"%@?q=%@&max=50", SCRIPTS_API, 
        [q stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: @""];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url] 
        completionHandler:^(NSData *data, NSURLResponse *r, NSError *e) {
        if (e || !data) {
            if (cb) cb(@[]);
            return;
        }
        
        @try {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *scripts = json[@"result"][@"scripts"];
            
            NSMutableArray *res = [NSMutableArray array];
            for (NSDictionary *d in scripts) {
                VR7Script *s = [[VR7Script alloc] init];
                s.id = d[@"_id"];
                s.title = d[@"title"];
                s.game = d[@"game"][@"name"];
                s.script = d[@"script"];
                [res addObject:s];
            }
            
            if (cb) cb(res);
        } @catch (NSException *ex) {
            if (cb) cb(@[]);
        }
    }] resume];
}

+ (void)addFavorite:(VR7Script *)s {
    if (!g_Favorites) g_Favorites = [NSMutableArray array];
    [g_Favorites addObject:@{@"id":s.id, @"title":s.title, @"script":s.script}];
    [[NSUserDefaults standardUserDefaults] setObject:g_Favorites forKey:@"VR7_Favs"];
}

+ (NSArray *)getFavorites {
    if (!g_Favorites) {
        g_Favorites = [NSMutableArray arrayWithArray:
            [[NSUserDefaults standardUserDefaults] arrayForKey:@"VR7_Favs"] ?: @[]];
    }
    return g_Favorites;
}

@end

// =====================================================
// EXECUTOR
// =====================================================

@interface VR7Exec : NSObject
+ (void)run:(NSString *)code;
+ (void)setupEnv:(lua_State *)L;
@end

@implementation VR7Exec

+ (void)setupEnv:(lua_State *)L {
    if (!L || !luaL_loadstring) return;
    
    const char *env = 
"_G.VR7='5.0.0'\n"
"task=task or {wait=wait,spawn=spawn}\n"
"workspace=game:GetService('Workspace')\n"
"players=game:GetService('Players')\n"
"localplayer=players.LocalPlayer\n"
"print('✅ VR7 v5.0.0')\n";
    
    if (luaL_loadstring(L, env) == 0) {
        lua_pcall(L, 0, 0, 0);
    }
}

+ (void)run:(NSString *)code {
    lua_State *L = [VR7Roblox getLuaState];
    if (!L) {
        [self sendError:@"Lua not ready"];
        return;
    }
    
    static dispatch_once_t once;
    dispatch_once(&once, ^{ [self setupEnv:L]; });
    
    code = [code stringByReplacingOccurrencesOfString:@"wait(" withString:@"task.wait("];
    
    // Try Luau
    if (luau_compile && luau_load) {
        size_t outSize;
        char *bc = luau_compile([code UTF8String], code.length, NULL, &outSize);
        if (bc) {
            if (luau_load(L, "VR7", bc, outSize, 0) == 0) {
                if (lua_pcall(L, 0, 0, 0) == 0) {
                    free(bc);
                    [self sendSuccess:@"Executed"];
                    return;
                }
            }
            free(bc);
        }
    }
    
    // Fallback
    if (luaL_loadstring(L, [code UTF8String]) != 0) {
        [self sendError:@"Load failed"];
        return;
    }
    
    if (lua_pcall(L, 0, 0, 0) != 0) {
        [self sendError:@"Exec failed"];
        return;
    }
    
    [self sendSuccess:@"Executed"];
}

+ (void)sendError:(NSString *)m {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!g_WebView) return;
        [g_WebView evaluateJavaScript:[NSString stringWithFormat:@"log('❌ %@','error')", m] completionHandler:nil];
    });
}

+ (void)sendSuccess:(NSString *)m {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!g_WebView) return;
        [g_WebView evaluateJavaScript:[NSString stringWithFormat:@"log('✅ %@','success')", m] completionHandler:nil];
    });
}

@end

// =====================================================
// MESSAGE HANDLER
// =====================================================

@interface VR7Handler : NSObject <WKScriptMessageHandler>
@end

@implementation VR7Handler
- (void)userContentController:(WKUserContentController *)c didReceiveScriptMessage:(WKScriptMessage *)m {
    if ([m.name isEqualToString:@"exec"]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [VR7Exec run:m.body];
        });
    }
    else if ([m.name isEqualToString:@"search"]) {
        [VR7Hub search:m.body completion:^(NSArray *scripts) {
            NSMutableArray *arr = [NSMutableArray array];
            for (VR7Script *s in scripts) {
                [arr addObject:@{@"id":s.id,@"title":s.title,@"game":s.game,@"script":s.script}];
            }
            NSData *json = [NSJSONSerialization dataWithJSONObject:arr options:0 error:nil];
            NSString *js = [NSString stringWithFormat:@"showResults(%@)", 
                [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [g_WebView evaluateJavaScript:js completionHandler:nil];
            });
        }];
    }
    else if ([m.name isEqualToString:@"close"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            g_WebView.hidden = YES;
            g_FloatingButton.hidden = NO;
        });
    }
}
@end

// =====================================================
// UI
// =====================================================

@interface VR7Button : UIButton
@end
@implementation VR7Button
- (void)tap {
    g_WebView.hidden = NO;
    self.hidden = YES;
}
@end

void VR7_InitUI() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *w = [[UIApplication sharedApplication] windows].firstObject;
        if (!w) return;
        
        // Floating button
        VR7Button *btn = [[VR7Button alloc] initWithFrame:CGRectMake(w.bounds.size.width-80, 150, 60, 60)];
        btn.backgroundColor = [UIColor colorWithRed:0.5 green:0 blue:1 alpha:1];
        [btn setTitle:@"VR7" forState:0];
        btn.layer.cornerRadius = 30;
        [btn addTarget:btn action:@selector(tap) forControlEvents:1];
        g_FloatingButton = btn;
        [w addSubview:btn];
        btn.hidden = YES;
        
        // WebView
        WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
        VR7Handler *handler = [[VR7Handler alloc] init];
        [cfg.userContentController addScriptMessageHandler:handler name:@"exec"];
        [cfg.userContentController addScriptMessageHandler:handler name:@"search"];
        [cfg.userContentController addScriptMessageHandler:handler name:@"close"];
        
        g_WebView = [[WKWebView alloc] initWithFrame:w.bounds configuration:cfg];
        g_WebView.opaque = NO;
        g_WebView.backgroundColor = [UIColor clearColor];
        
        NSString *html = @"<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width,initial-scale=1'><style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:-apple-system;background:linear-gradient(135deg,#0a0015,#1a0030);color:#fff;height:100vh;padding:15px}.header{text-align:center;padding:20px;background:rgba(10,0,20,0.7);border:2px solid rgba(128,0,255,0.4);border-radius:20px;margin-bottom:15px}.logo{font-size:36px;font-weight:900;color:#fff}.close{position:absolute;top:15px;right:15px;width:30px;height:30px;background:rgba(255,0,100,0.3);border-radius:50%;color:#fff;border:none}.tabs{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:15px}.tab{padding:12px;background:rgba(128,0,255,0.1);border:2px solid rgba(128,0,255,0.3);border-radius:12px;text-align:center;font-size:12px;font-weight:700;color:rgba(255,255,255,0.6)}.tab.active{background:rgba(128,0,255,0.3);color:#fff}.search{position:relative;margin-bottom:15px}.search input{width:100%;padding:12px;background:rgba(0,0,0,0.4);border:2px solid rgba(128,0,255,0.3);border-radius:12px;color:#fff;font-size:13px}.content{flex:1;overflow-y:auto;background:rgba(5,0,15,0.6);border:2px solid rgba(128,0,255,0.3);border-radius:15px;padding:10px;height:50vh}.script{background:rgba(10,0,20,0.8);border:1px solid rgba(128,0,255,0.3);border-radius:10px;padding:10px;margin-bottom:10px}.script h3{font-size:13px;margin-bottom:5px}.script button{padding:8px;background:linear-gradient(135deg,#8000ff,#6000dd);border:none;border-radius:8px;color:#fff;font-size:11px;font-weight:700;margin-top:8px}textarea{width:100%;height:200px;background:rgba(0,0,0,0.4);border:2px solid rgba(128,0,255,0.3);border-radius:12px;color:#00ff88;padding:10px;font-family:monospace;font-size:12px;resize:none;margin-bottom:10px}.buttons{display:grid;grid-template-columns:1fr 1fr;gap:10px}button{padding:12px;background:linear-gradient(135deg,#8000ff,#6000dd);border:none;border-radius:10px;color:#fff;font-weight:700;font-size:12px}.console{background:rgba(0,0,0,0.6);border:2px solid rgba(128,0,255,0.2);border-radius:10px;padding:8px;height:60px;overflow-y:auto;font-size:10px;font-family:monospace;margin-top:10px}.success{color:#00ff88}.error{color:#ff0066}</style></head><body><div class='header'><div class='logo'>VR7</div><button class='close' onclick='close()'>×</button></div><div class='tabs'><div class='tab active' onclick='switchTab(0)'>SEARCH</div><div class='tab' onclick='switchTab(1)'>EDITOR</div></div><div id='searchView'><div class='search'><input id='searchInput' placeholder='Search scripts...' onkeyup='search()'></div><div class='content' id='results'></div></div><div id='editorView' style='display:none'><textarea id='code' placeholder='-- VR7 v5.0\\nprint(\"Hello!\")'></textarea><div class='buttons'><button onclick='exec()'>▶ RUN</button><button onclick='clear()'>CLEAR</button></div><div class='console' id='console'></div></div><script>let tab=0;function switchTab(t){tab=t;document.querySelectorAll('.tab').forEach((e,i)=>e.classList.toggle('active',i===t));document.getElementById('searchView').style.display=t===0?'block':'none';document.getElementById('editorView').style.display=t===1?'block':'none'}function search(){const q=document.getElementById('searchInput').value;webkit.messageHandlers.search.postMessage(q)}function showResults(scripts){const c=document.getElementById('results');c.innerHTML='';scripts.forEach(s=>{const div=document.createElement('div');div.className='script';div.innerHTML=`<h3>${s.title}</h3><p style='font-size:11px;color:rgba(255,255,255,0.5)'>${s.game}</p><button onclick='run(\"${s.script.replace(/\"/g,'&quot;')}\")'>▶ Execute</button>`;c.appendChild(div)})}function run(code){document.getElementById('code').value=decodeURIComponent(code);switchTab(1);webkit.messageHandlers.exec.postMessage(code)}function exec(){const c=document.getElementById('code').value;webkit.messageHandlers.exec.postMessage(c)}function clear(){document.getElementById('code').value='';document.getElementById('console').innerHTML=''}function log(m,t){document.getElementById('console').innerHTML+=`<div class='${t}'>${m}</div>`}function close(){webkit.messageHandlers.close.postMessage('')}setTimeout(()=>webkit.messageHandlers.search.postMessage(''),500)</script></body></html>";
        
        [g_WebView loadHTMLString:html baseURL:nil];
        g_WebView.hidden = YES;
        [w addSubview:g_WebView];
    });
}

// =====================================================
// GAME MONITOR
// =====================================================

void VR7_Monitor() {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            sleep(1);
            BOOL inGame = [VR7Roblox isInGame];
            
            if (inGame && !g_InGame) {
                g_InGame = YES;
                VR7_LOG("Game loaded");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    g_WebView.hidden = NO;
                    g_FloatingButton.hidden = NO;
                });
            } else if (!inGame && g_InGame) {
                g_InGame = NO;
                g_LuaState = NULL;
                dispatch_async(dispatch_get_main_queue(), ^{
                    g_WebView.hidden = YES;
                    g_FloatingButton.hidden = YES;
                });
            }
        }
    });
}

// =====================================================
// LUA INIT
// =====================================================

void VR7_InitLua() {
    void *h = dlopen(NULL, RTLD_LAZY);
    #define LOAD(n) n = (n##_t)dlsym(h, #n); if(!n) n = (n##_t)dlsym(RTLD_DEFAULT, #n)
    LOAD(lua_gettop);LOAD(lua_settop);LOAD(lua_type);LOAD(lua_tolstring);
    LOAD(lua_pushstring);LOAD(lua_pushnil);LOAD(lua_pushboolean);
    LOAD(lua_call);LOAD(lua_pcall);LOAD(luaL_loadstring);
    LOAD(lua_getglobal);LOAD(lua_setglobal);LOAD(luau_load);LOAD(luau_compile);
    VR7_LOG("Lua API loaded");
}

// =====================================================
// PROTECTION
// =====================================================

static int (*original_stat)(const char *, struct stat *) = NULL;
static int hooked_stat(const char *p, struct stat *b) {
    if (strstr(p, "Cydia") || strstr(p, "substrate")) {
        errno = ENOENT;
        return -1;
    }
    return original_stat(p, b);
}

void VR7_Protect() {
    MSHookFunction((void *)stat, (void *)hooked_stat, (void **)&original_stat);
    VR7_LOG("Protection enabled");
}

// =====================================================
// MAIN INIT
// =====================================================

__attribute__((constructor))
static void VR7_Init() {
    @autoreleasepool {
        VR7_LOG("🚀 VR7 v" VR7_VERSION);
        
        g_XORKey = arc4random();
        g_XORKey = (g_XORKey << 32) | arc4random();
        
        VR7_Protect();
        [VR7Offsets initialize];
        VR7_InitLua();
        [VR7Roblox getBase];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            VR7_InitUI();
            VR7_Monitor();
        });
        
        VR7_LOG("✅ Ready");
    }
}
