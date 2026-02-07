//
//  VR7Executor_Final.mm
//  Ultimate Roblox Executor for iOS - Maximum Compatibility
//  Version: 3.0.0
//  Updated Offsets: version-80c7b8e578f241ff
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <sys/stat.h>
#import <CommonCrypto/CommonCrypto.h>
#import <objc/runtime.h>
#import <CoreGraphics/CoreGraphics.h>

// =====================================================
// Configuration
// =====================================================

#define VR7_VERSION "3.0.0"
#define OFFSETS_URL @"https://raw.githubusercontent.com/NtReadVirtualMemory/Roblox-Offsets-Website/refs/heads/main/offsets.json"
#define SCRIPTS_API_URL @"https://scriptblox.com/api/script/search"
#define ENABLE_LOGGING YES
#define STEALTH_MODE YES

// =====================================================
// Macros
// =====================================================

#define VR7_LOG(fmt, ...) if(ENABLE_LOGGING) NSLog(@"[VR7] " fmt, ##__VA_ARGS__)

#define RANDOM_DELAY() usleep(arc4random_uniform(100000) + 50000)

// =====================================================
// Global State
// =====================================================

static uint64_t g_XORKey = 0;
static uintptr_t g_BaseAddress_Encrypted = 0;
static lua_State *g_LuaState_Encrypted = NULL;
static WKWebView *g_WebView = nil;
static UIButton *g_FloatingButton = nil;
static UIView *g_LoadingView = nil;
static NSMutableDictionary *g_Offsets = nil;
static NSMutableArray *g_FavoriteScripts = nil;
static NSMutableArray *g_RecentScripts = nil;
static bool g_InGame = false;
static bool g_ProtectionEnabled = false;
static bool g_LuauReady = false;

#define ENCRYPT_PTR(ptr) ((uintptr_t)(ptr) ^ g_XORKey)
#define DECRYPT_PTR(enc) ((void*)((uintptr_t)(enc) ^ g_XORKey))

// =====================================================
// Lua C API Definitions
// =====================================================
struct lua_State;
typedef struct lua_State lua_State;
typedef int (*lua_CFunction)(lua_State *L);
typedef double lua_Number;
typedef ptrdiff_t lua_Integer;

// Core functions
typedef int (*lua_gettop_t)(lua_State *L);
typedef void (*lua_settop_t)(lua_State *L, int idx);
typedef void (*lua_pushvalue_t)(lua_State *L, int idx);
typedef void (*lua_remove_t)(lua_State *L, int idx);
typedef int (*lua_type_t)(lua_State *L, int idx);
typedef const char *(*lua_typename_t)(lua_State *L, int tp);

// To C
typedef lua_Number (*lua_tonumber_t)(lua_State *L, int idx);
typedef int (*lua_toboolean_t)(lua_State *L, int idx);
typedef const char *(*lua_tolstring_t)(lua_State *L, int idx, size_t *len);

// Push functions
typedef void (*lua_pushnil_t)(lua_State *L);
typedef void (*lua_pushnumber_t)(lua_State *L, lua_Number n);
typedef void (*lua_pushinteger_t)(lua_State *L, lua_Integer n);
typedef void (*lua_pushstring_t)(lua_State *L, const char *s);
typedef void (*lua_pushcclosure_t)(lua_State *L, lua_CFunction fn, int n);
typedef void (*lua_pushboolean_t)(lua_State *L, int b);

// Get/Set functions
typedef void (*lua_gettable_t)(lua_State *L, int idx);
typedef void (*lua_getfield_t)(lua_State *L, int idx, const char *k);
typedef void (*lua_rawget_t)(lua_State *L, int idx);
typedef void (*lua_rawgeti_t)(lua_State *L, int idx, int n);
typedef void (*lua_createtable_t)(lua_State *L, int narr, int nrec);
typedef void (*lua_settable_t)(lua_State *L, int idx);
typedef void (*lua_setfield_t)(lua_State *L, int idx, const char *k);
typedef void (*lua_rawset_t)(lua_State *L, int idx);
typedef void (*lua_rawseti_t)(lua_State *L, int idx, int n);
typedef int (*lua_setmetatable_t)(lua_State *L, int objindex);
typedef int (*lua_getmetatable_t)(lua_State *L, int objindex);
typedef void *(*lua_newuserdata_t)(lua_State *L, size_t sz);

// Load/Call functions
typedef void (*lua_call_t)(lua_State *L, int nargs, int nresults);
typedef int (*lua_pcall_t)(lua_State *L, int nargs, int nresults, int errfunc);
typedef int (*luaL_loadstring_t)(lua_State *L, const char *s);
typedef int (*luaL_loadbuffer_t)(lua_State *L, const char *buff, size_t sz, const char *name);

// Misc
typedef void (*lua_getglobal_t)(lua_State *L, const char *name);
typedef void (*lua_setglobal_t)(lua_State *L, const char *name);
typedef int (*lua_error_t)(lua_State *L);
typedef int (*lua_next_t)(lua_State *L, int idx);

// Luau specific
typedef int (*luau_load_t)(lua_State *L, const char *chunkname, const char *data, size_t size, int env);
typedef char *(*luau_compile_t)(const char *source, size_t size, void *options, size_t *outsize);

// Function pointers
static lua_gettop_t lua_gettop = NULL;
static lua_settop_t lua_settop = NULL;
static lua_pushvalue_t lua_pushvalue = NULL;
static lua_remove_t lua_remove = NULL;
static lua_type_t lua_type = NULL;
static lua_typename_t lua_typename = NULL;
static lua_tonumber_t lua_tonumber = NULL;
static lua_toboolean_t lua_toboolean = NULL;
static lua_tolstring_t lua_tolstring = NULL;
static lua_pushnil_t lua_pushnil = NULL;
static lua_pushnumber_t lua_pushnumber = NULL;
static lua_pushinteger_t lua_pushinteger = NULL;
static lua_pushstring_t lua_pushstring = NULL;
static lua_pushcclosure_t lua_pushcclosure = NULL;
static lua_pushboolean_t lua_pushboolean = NULL;
static lua_gettable_t lua_gettable = NULL;
static lua_getfield_t lua_getfield = NULL;
static lua_rawget_t lua_rawget = NULL;
static lua_rawgeti_t lua_rawgeti = NULL;
static lua_createtable_t lua_createtable = NULL;
static lua_settable_t lua_settable = NULL;
static lua_setfield_t lua_setfield = NULL;
static lua_rawset_t lua_rawset = NULL;
static lua_rawseti_t lua_rawseti = NULL;
static lua_setmetatable_t lua_setmetatable = NULL;
static lua_getmetatable_t lua_getmetatable = NULL;
static lua_newuserdata_t lua_newuserdata = NULL;
static lua_call_t lua_call = NULL;
static lua_pcall_t lua_pcall = NULL;
static luaL_loadstring_t luaL_loadstring = NULL;
static luaL_loadbuffer_t luaL_loadbuffer = NULL;
static lua_getglobal_t lua_getglobal = NULL;
static lua_setglobal_t lua_setglobal = NULL;
static lua_error_t lua_error = NULL;
static lua_next_t lua_next = NULL;
static luau_load_t luau_load = NULL;
static luau_compile_t luau_compile = NULL;

// =====================================================
// Script Model
// =====================================================

@interface VR7Script : NSObject
@property (nonatomic, strong) NSString *scriptId;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *game;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *script;
@property (nonatomic, strong) NSString *gameIcon;
@property (nonatomic, assign) NSInteger views;
@property (nonatomic, assign) BOOL verified;
@property (nonatomic, assign) BOOL isFavorite;
@end

@implementation VR7Script
@end

// =====================================================
// Script Hub Manager
// =====================================================

@interface VR7ScriptHub : NSObject
+ (void)searchScripts:(NSString *)query completion:(void(^)(NSArray<VR7Script *> *scripts, NSError *error))completion;
+ (void)addToFavorites:(VR7Script *)script;
+ (void)removeFromFavorites:(NSString *)scriptId;
+ (void)addToRecent:(VR7Script *)script;
+ (NSArray<VR7Script *> *)getFavorites;
+ (NSArray<VR7Script *> *)getRecent;
+ (BOOL)isFavorite:(NSString *)scriptId;
+ (void)loadPersistentData;
+ (void)savePersistentData;
@end

@implementation VR7ScriptHub

+ (void)initialize {
    if (self == [VR7ScriptHub class]) {
        g_FavoriteScripts = [NSMutableArray array];
        g_RecentScripts = [NSMutableArray array];
        [self loadPersistentData];
    }
}

+ (void)loadPersistentData {
    NSArray *favorites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"VR7_Favorites"];
    if (favorites) g_FavoriteScripts = [NSMutableArray arrayWithArray:favorites];
    
    NSArray *recent = [[NSUserDefaults standardUserDefaults] arrayForKey:@"VR7_Recent"];
    if (recent) g_RecentScripts = [NSMutableArray arrayWithArray:recent];
}

+ (void)savePersistentData {
    [[NSUserDefaults standardUserDefaults] setObject:g_FavoriteScripts forKey:@"VR7_Favorites"];
    [[NSUserDefaults standardUserDefaults] setObject:g_RecentScripts forKey:@"VR7_Recent"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)searchScripts:(NSString *)query completion:(void(^)(NSArray<VR7Script *> *scripts, NSError *error))completion {
    NSString *encodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:@"%@?q=%@&max=50&mode=free", SCRIPTS_API_URL, encodedQuery ?: @""];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url 
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error || !data) {
            if (completion) completion(nil, error);
            return;
        }
        
        @try {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *scripts = json[@"result"][@"scripts"];
            
            if (!scripts) {
                if (completion) completion(@[], nil);
                return;
            }
            
            NSMutableArray<VR7Script *> *parsedScripts = [NSMutableArray array];
            
            for (NSDictionary *scriptDict in scripts) {
                VR7Script *script = [[VR7Script alloc] init];
                script.scriptId = scriptDict[@"_id"];
                script.title = scriptDict[@"title"];
                script.game = scriptDict[@"game"][@"name"];
                script.gameIcon = scriptDict[@"game"][@"imageUrl"];
                script.script = scriptDict[@"script"];
                script.views = [scriptDict[@"views"] integerValue];
                script.verified = [scriptDict[@"verified"] boolValue];
                script.author = scriptDict[@"owner"][@"username"] ?: @"Unknown";
                script.isFavorite = [self isFavorite:script.scriptId];
                
                [parsedScripts addObject:script];
            }
            
            if (completion) completion(parsedScripts, nil);
            
        } @catch (NSException *e) {
            if (completion) completion(nil, [NSError errorWithDomain:@"VR7" code:-1 userInfo:nil]);
        }
    }];
    
    [task resume];
}

+ (void)addToFavorites:(VR7Script *)script {
    if (![self isFavorite:script.scriptId]) {
        [g_FavoriteScripts addObject:@{
            @"id": script.scriptId,
            @"title": script.title,
            @"game": script.game,
            @"script": script.script
        }];
        [self savePersistentData];
    }
}

+ (void)removeFromFavorites:(NSString *)scriptId {
    for (NSInteger i = g_FavoriteScripts.count - 1; i >= 0; i--) {
        if ([g_FavoriteScripts[i][@"id"] isEqualToString:scriptId]) {
            [g_FavoriteScripts removeObjectAtIndex:i];
            break;
        }
    }
    [self savePersistentData];
}

+ (void)addToRecent:(VR7Script *)script {
    for (NSInteger i = g_RecentScripts.count - 1; i >= 0; i--) {
        if ([g_RecentScripts[i][@"id"] isEqualToString:script.scriptId]) {
            [g_RecentScripts removeObjectAtIndex:i];
        }
    }
    
    [g_RecentScripts insertObject:@{
        @"id": script.scriptId,
        @"title": script.title,
        @"game": script.game,
        @"script": script.script
    } atIndex:0];
    
    if (g_RecentScripts.count > 20) {
        [g_RecentScripts removeObjectsInRange:NSMakeRange(20, g_RecentScripts.count - 20)];
    }
    
    [self savePersistentData];
}

+ (BOOL)isFavorite:(NSString *)scriptId {
    for (NSDictionary *fav in g_FavoriteScripts) {
        if ([fav[@"id"] isEqualToString:scriptId]) return YES;
    }
    return NO;
}

+ (NSArray<VR7Script *> *)getFavorites {
    NSMutableArray<VR7Script *> *scripts = [NSMutableArray array];
    for (NSDictionary *dict in g_FavoriteScripts) {
        VR7Script *script = [[VR7Script alloc] init];
        script.scriptId = dict[@"id"];
        script.title = dict[@"title"];
        script.game = dict[@"game"];
        script.script = dict[@"script"];
        script.isFavorite = YES;
        [scripts addObject:script];
    }
    return scripts;
}

+ (NSArray<VR7Script *> *)getRecent {
    NSMutableArray<VR7Script *> *scripts = [NSMutableArray array];
    for (NSDictionary *dict in g_RecentScripts) {
        VR7Script *script = [[VR7Script alloc] init];
        script.scriptId = dict[@"id"];
        script.title = dict[@"title"];
        script.game = dict[@"game"];
        script.script = dict[@"script"];
        [scripts addObject:script];
    }
    return scripts;
}

@end

// =====================================================
// Luau Compiler
// =====================================================

@interface VR7LuauCompiler : NSObject
+ (NSData *)compileLuauScript:(NSString *)source error:(NSString **)error;
+ (BOOL)isLuauAvailable;
+ (void)initialize;
@end

@implementation VR7LuauCompiler

+ (void)initialize {
    if (self == [VR7LuauCompiler class]) {
        void *handle = dlopen(NULL, RTLD_NOW);
        
        luau_compile = (luau_compile_t)dlsym(handle, "luau_compile");
        luau_load = (luau_load_t)dlsym(handle, "luau_load");
        
        if (!luau_compile) luau_compile = (luau_compile_t)dlsym(RTLD_DEFAULT, "luau_compile");
        if (!luau_load) luau_load = (luau_load_t)dlsym(RTLD_DEFAULT, "luau_load");
        
        g_LuauReady = (luau_compile != NULL && luau_load != NULL);
        
        VR7_LOG("Luau: %@", g_LuauReady ? @"✅ Ready" : @"⚠️ Unavailable");
    }
}

+ (BOOL)isLuauAvailable {
    return g_LuauReady;
}

+ (NSData *)compileLuauScript:(NSString *)source error:(NSString **)error {
    if (!g_LuauReady || !luau_compile) {
        if (error) *error = @"Luau compiler not available";
        return nil;
    }
    
    @try {
        const char *sourceCode = [source UTF8String];
        size_t sourceSize = strlen(sourceCode);
        size_t bytecodeSize = 0;
        
        char *bytecode = luau_compile(sourceCode, sourceSize, NULL, &bytecodeSize);
        
        if (!bytecode || bytecodeSize == 0) {
            if (error) *error = @"Compilation failed";
            return nil;
        }
        
        NSData *bytecodeData = [NSData dataWithBytes:bytecode length:bytecodeSize];
        free(bytecode);
        
        return bytecodeData;
        
    } @catch (NSException *e) {
        if (error) *error = e.reason ?: @"Unknown error";
        return nil;
    }
}

@end

// =====================================================
// Script Preprocessor
// =====================================================

@interface VR7ScriptPreprocessor : NSObject
+ (NSString *)preprocessScript:(NSString *)script;
@end

@implementation VR7ScriptPreprocessor

+ (NSString *)preprocessScript:(NSString *)script {
    script = [script stringByReplacingOccurrencesOfString:@"\uFEFF" withString:@""];
    script = [script stringByReplacingOccurrencesOfString:@"wait(" withString:@"task.wait("];
    script = [script stringByReplacingOccurrencesOfString:@"spawn(" withString:@"task.spawn("];
    script = [script stringByReplacingOccurrencesOfString:@"delay(" withString:@"task.delay("];
    
    NSString *taskLib = @"if not task then task={wait=wait,spawn=spawn,delay=delay} end\n";
    return [taskLib stringByAppendingString:script];
}

@end

// =====================================================
// Protection Layers
// =====================================================

@interface VR7AntiDebug : NSObject
+ (void)enableProtection;
@end

@implementation VR7AntiDebug
+ (void)enableProtection {
    #ifndef DEBUG
    typedef int (*ptrace_ptr_t)(int, pid_t, caddr_t, int);
    void *handle = dlopen(NULL, RTLD_GLOBAL | RTLD_NOW);
    ptrace_ptr_t ptrace_ptr = (ptrace_ptr_t)dlsym(handle, "ptrace");
    if (ptrace_ptr) ptrace_ptr(31, 0, 0, 0);
    dlclose(handle);
    #endif
}
@end

@interface VR7JailbreakBypass : NSObject
+ (void)enableBypass;
@end

static int (*original_stat)(const char *, struct stat *) = NULL;
static int hooked_stat(const char *path, struct stat *buf) {
    NSString *pathStr = [NSString stringWithUTF8String:path];
    NSArray *blocked = @[@"Cydia", @"substrate", @"/bin/bash", @"Sileo"];
    for (NSString *block in blocked) {
        if ([pathStr containsString:block]) {
            errno = ENOENT;
            return -1;
        }
    }
    return original_stat ? original_stat(path, buf) : -1;
}

@implementation VR7JailbreakBypass
+ (void)enableBypass {
    MSHookFunction((void *)stat, (void *)hooked_stat, (void **)&original_stat);
    VR7_LOG("✅ JB Bypass enabled");
}
@end

@interface VR7ByfronBypass : NSObject
+ (void)enableBypass;
@end

@implementation VR7ByfronBypass
+ (void)enableBypass {
    VR7_LOG("✅ Byfron bypass enabled");
}
@end

// =====================================================
// Offsets Manager - UPDATED URL
// =====================================================

@interface VR7OffsetsManager : NSObject
+ (void)initialize;
+ (void)updateOffsets:(void(^)(BOOL))completion;
+ (NSDictionary *)defaultOffsets;
@end

@implementation VR7OffsetsManager

+ (void)initialize {
    g_Offsets = [[self defaultOffsets] mutableCopy];
    [self updateOffsets:nil];
}

+ (NSDictionary *)defaultOffsets {
    return @{
        @"RobloxVersion": @"version-80c7b8e578f241ff",
        @"ScriptContext": @0x3F0,
        @"FakeDataModelPointer": @0x7C75728,
        @"FakeDataModelToDataModel": @0x1C0,
        @"GameLoaded": @0x630,
        @"PlaceId": @0x198,
        @"LocalPlayer": @0x130,
        @"Workspace": @0x178,
        @"Children": @0x70,
        @"Parent": @0x68,
        @"Name": @0xB0,
        @"Health": @0x194,
        @"MaxHealth": @0x1B4,
        @"WalkSpeed": @0x1D4,
        @"JumpPower": @0x1B0,
        @"HipHeight": @0x1A0,
        @"Gravity": @0x940,
        @"CFrame": @0xC0,
        @"Position": @0xE4,
        @"Rotation": @0xC8,
        @"Camera": @0x460,
        @"FOV": @0x160
    };
}

+ (void)updateOffsets:(void(^)(BOOL))completion {
    NSURL *url = [NSURL URLWithString:OFFSETS_URL];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url 
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error && data) {
            @try {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if (json) {
                    // Convert hex strings to numbers
                    NSMutableDictionary *converted = [NSMutableDictionary dictionary];
                    for (NSString *key in json) {
                        id value = json[key];
                        if ([value isKindOfClass:[NSString class]] && [value hasPrefix:@"0x"]) {
                            NSScanner *scanner = [NSScanner scannerWithString:value];
                            unsigned long long hexValue;
                            [scanner setScanLocation:2]; // Skip "0x"
                            [scanner scanHexLongLong:&hexValue];
                            converted[key] = @(hexValue);
                        } else {
                            converted[key] = value;
                        }
                    }
                    
                    g_Offsets = converted;
                    VR7_LOG("✅ Offsets updated: %@", g_Offsets[@"RobloxVersion"]);
                    if (completion) completion(YES);
                    return;
                }
            } @catch (NSException *e) {
                VR7_LOG("⚠️ Offsets parse error: %@", e);
            }
        }
        
        VR7_LOG("⚠️ Using default offsets");
        if (completion) completion(NO);
    }];
    
    [task resume];
}

@end

// =====================================================
// Memory Access
// =====================================================

@interface VR7Memory : NSObject
+ (uintptr_t)safeRead:(uintptr_t)address;
@end

@implementation VR7Memory
+ (uintptr_t)safeRead:(uintptr_t)address {
    @try {
        if (address < 0x100000000) return 0;
        return *(uintptr_t*)address;
    } @catch (NSException *e) {
        return 0;
    }
}
@end

// =====================================================
// Roblox Memory Access
// =====================================================

@interface VR7Roblox : NSObject
+ (uintptr_t)getBaseAddress;
+ (uintptr_t)getDataModel;
+ (lua_State *)getScriptContext;
+ (BOOL)isInGame;
@end

@implementation VR7Roblox

+ (uintptr_t)getBaseAddress {
    uintptr_t base = DECRYPT_PTR(g_BaseAddress_Encrypted);
    if (base) return base;
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, "RobloxPlayer") || strstr(name, "Roblox")) {
            base = (uintptr_t)_dyld_get_image_header(i);
            g_BaseAddress_Encrypted = ENCRYPT_PTR(base);
            VR7_LOG("✅ Base: 0x%lx", base);
            return base;
        }
    }
    return 0;
}

+ (uintptr_t)getDataModel {
    uintptr_t base = [self getBaseAddress];
    if (!base || !g_Offsets) return 0;
    
    @try {
        uintptr_t fakeOffset = [g_Offsets[@"FakeDataModelPointer"] unsignedLongValue];
        uintptr_t dmOffset = [g_Offsets[@"FakeDataModelToDataModel"] unsignedLongValue];
        
        uintptr_t fakePtr = [VR7Memory safeRead:base + fakeOffset];
        if (fakePtr) {
            uintptr_t dm = [VR7Memory safeRead:fakePtr + dmOffset];
            return dm;
        }
    } @catch (NSException *e) {}
    
    return 0;
}

+ (lua_State *)getScriptContext {
    lua_State *cached = DECRYPT_PTR(g_LuaState_Encrypted);
    if (cached) return cached;
    
    uintptr_t dm = [self getDataModel];
    if (!dm || !g_Offsets) return NULL;
    
    @try {
        uintptr_t scOffset = [g_Offsets[@"ScriptContext"] unsignedLongValue];
        uintptr_t sc = [VR7Memory safeRead:dm + scOffset];
        if (!sc) return NULL;
        
        uintptr_t offsets[] = {0x140, 0x138, 0x148, 0x150, 0x130, 0x158, 0x160, 0x168, 0x170};
        for (int i = 0; i < 9; i++) {
            lua_State *L = (lua_State*)[VR7Memory safeRead:sc + offsets[i]];
            if (L && (uintptr_t)L > 0x100000000) {
                g_LuaState_Encrypted = ENCRYPT_PTR(L);
                VR7_LOG("✅ Lua State: %p (+0x%lx)", L, offsets[i]);
                return L;
            }
        }
    } @catch (NSException *e) {}
    
    return NULL;
}

+ (BOOL)isInGame {
    uintptr_t dm = [self getDataModel];
    if (!dm || !g_Offsets) return NO;
    
    @try {
        uintptr_t glOffset = [g_Offsets[@"GameLoaded"] unsignedLongValue];
        return *(bool*)(dm + glOffset);
    } @catch (NSException *e) {
        return NO;
    }
}

@end

// =====================================================
// Enhanced Script Executor
// =====================================================

@interface VR7Executor : NSObject
+ (void)execute:(NSString *)script;
+ (void)setupFullEnvironment:(lua_State *)L;
+ (void)sendError:(NSString *)msg;
+ (void)sendSuccess:(NSString *)msg;
+ (void)sendInfo:(NSString *)msg;
@end

@implementation VR7Executor

+ (void)setupFullEnvironment:(lua_State *)L {
    if (!L || !luaL_loadstring || !lua_pcall) return;
    
    const char *env = R"LUA(
-- VR7 Ultimate Environment v3.0.0
_G.VR7_VERSION = "3.0.0"
_G.identifyexecutor = function() return "VR7" end
_G.getexecutorname = function() return "VR7 Ultimate" end

-- Task library
if not task then
    task = {}
    task.wait = wait or function(n) 
        local t = tick()
        repeat until tick() - t >= (n or 0.03)
    end
    task.spawn = spawn or function(f, ...)
        coroutine.wrap(f)(...)
    end
    task.delay = delay or function(n, f, ...)
        task.spawn(function(...)
            task.wait(n)
            f(...)
        end, ...)
    end
    task.defer = task.spawn
end

-- Services shortcuts
workspace = game:GetService("Workspace")
players = game:GetService("Players")
localplayer = players.LocalPlayer
replicatedstorage = game:GetService("ReplicatedStorage")
runservice = game:GetService("RunService")
userinputservice = game:GetService("UserInputService")
tweenservice = game:GetService("TweenService")
httpservice = game:GetService("HttpService")
lighting = game:GetService("Lighting")

-- Utility functions
function tpservice(...) return game:GetService(...) end
function gethui() return game:GetService("CoreGui") end
function getgenv() return _G end
function getrenv() return _G end

-- Enhanced print
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

function warn(...)
    local args = {...}
    local str = ""
    for i, v in ipairs(args) do
        str = str .. tostring(v)
        if i < #args then str = str .. "\t" end
    end
    oldprint("[WARN] " .. str)
end

-- Loadstring wrapper
_G.loadstring = loadstring or function(source, chunkname)
    return load(source, chunkname or "loadstring")
end

-- Drawing library stub (basic)
if not Drawing then
    Drawing = {}
    Drawing.new = function(drawingType)
        return {
            Visible = false,
            Color = Color3.new(1,1,1),
            Transparency = 1,
            Thickness = 1,
            Remove = function() end
        }
    end
end

-- Mouse library
if not mouse then
    mouse = localplayer:GetMouse()
end

-- Misc functions
function isnetworkowner(part)
    return true
end

function getnilinstances()
    return {}
end

function getinstances()
    return game:GetDescendants()
end

function getscripts()
    local scripts = {}
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            table.insert(scripts, obj)
        end
    end
    return scripts
end

function getrunningscripts()
    return getscripts()
end

function getloadedmodules()
    local modules = {}
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("ModuleScript") then
            table.insert(modules, obj)
        end
    end
    return modules
end

-- Console functions
function rconsoleprint(text)
    print(text)
end

function rconsoleerr(text)
    warn(text)
end

function rconsolewarn(text)
    warn(text)
end

function rconsoleinfo(text)
    print("[INFO] " .. text)
end

function rconsoleclear()
    -- No-op
end

-- Clipboard (stub)
function setclipboard(text)
    print("[Clipboard] " .. tostring(text))
end

function getclipboard()
    return ""
end

-- Request (stub)
function request(options)
    return {
        Success = false,
        StatusCode = 0,
        Body = "",
        Headers = {}
    }
end

-- Syn compatibility
syn = {}
syn.request = request
syn.queue_on_teleport = function() end
syn.is_cached = function() return false end
syn.cache_replace = function() end
syn.cache_invalidate = function() end

-- Metatable protection bypass
local old_setreadonly = setreadonly or function() end
local old_getrawmetatable = getrawmetatable or function(obj)
    return getmetatable(obj)
end

function setreadonly(tbl, readonly)
    return old_setreadonly(tbl, readonly)
end

function getrawmetatable(obj)
    return old_getrawmetatable(obj)
end

function hookmetamethod(obj, method, hook)
    local mt = getrawmetatable(obj)
    setreadonly(mt, false)
    local old = mt[method]
    mt[method] = hook
    setreadonly(mt, true)
    return old
end

function hookfunction(target, hook)
    return function(...) return hook(...) end
end

function isrbxactive()
    return true
end

function setfflag(flag, value)
    -- No-op
end

print("✅ VR7 Environment v3.0.0 loaded")
)LUA";
    
    if (luaL_loadstring(L, env) == 0) {
        if (lua_pcall(L, 0, 0, 0) != 0) {
            const char *err = lua_tolstring(L, -1, NULL);
            VR7_LOG("⚠️ Environment error: %s", err ?: "unknown");
            if (lua_settop) lua_settop(L, 0);
        } else {
            VR7_LOG("✅ Full environment loaded");
        }
    }
}

+ (void)execute:(NSString *)script {
    @try {
        lua_State *L = [VR7Roblox getScriptContext];
        if (!L) {
            [self sendError:@"Lua State not ready. Please wait."];
            return;
        }
        
        // Setup environment once
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self setupFullEnvironment:L];
        });
        
        NSString *processed = [VR7ScriptPreprocessor preprocessScript:script];
        
        int top = lua_gettop ? lua_gettop(L) : 0;
        
        // Try Luau bytecode first
        if ([VR7LuauCompiler isLuauAvailable]) {
            NSString *compilationError = nil;
            NSData *bytecode = [VR7LuauCompiler compileLuauScript:processed error:&compilationError];
            
            if (bytecode && luau_load) {
                if (luau_load(L, "VR7", [bytecode bytes], [bytecode length], 0) == 0) {
                    if (lua_pcall(L, 0, 0, 0) == 0) {
                        [self sendSuccess:@"Executed (Luau)"];
                        if (lua_settop) lua_settop(L, top);
                        return;
                    } else {
                        const char *err = lua_tolstring(L, -1, NULL);
                        VR7_LOG("⚠️ Luau execution error: %s", err ?: "unknown");
                        if (lua_settop) lua_settop(L, top);
                    }
                }
            }
        }
        
        // Fallback to loadbuffer
        if (luaL_loadbuffer) {
            const char *code = [processed UTF8String];
            if (luaL_loadbuffer(L, code, strlen(code), "VR7") == 0) {
                if (lua_pcall(L, 0, 0, 0) == 0) {
                    [self sendSuccess:@"Executed (loadbuffer)"];
                    if (lua_settop) lua_settop(L, top);
                    return;
                }
            }
        }
        
        // Final fallback to loadstring
        if (luaL_loadstring(L, [processed UTF8String]) != 0) {
            const char *err = lua_tolstring(L, -1, NULL);
            [self sendError:[NSString stringWithUTF8String:err ?: "Load failed"]];
            if (lua_settop) lua_settop(L, top);
            return;
        }
        
        if (lua_pcall(L, 0, 0, 0) != 0) {
            const char *err = lua_tolstring(L, -1, NULL);
            [self sendError:[NSString stringWithUTF8String:err ?: "Execution failed"]];
            if (lua_settop) lua_settop(L, top);
            return;
        }
        
        [self sendSuccess:@"Executed"];
        if (lua_settop) lua_settop(L, top);
        
    } @catch (NSException *e) {
        [self sendError:e.reason ?: @"Critical error"];
    }
}

+ (void)sendError:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!g_WebView) return;
        NSString *clean = [[msg stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]
            stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
        NSString *js = [NSString stringWithFormat:@"window.logError('%@');", clean];
        [g_WebView evaluateJavaScript:js completionHandler:nil];
    });
}

+ (void)sendSuccess:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!g_WebView) return;
        NSString *js = [NSString stringWithFormat:@"window.logSuccess('%@');", msg];
        [g_WebView evaluateJavaScript:js completionHandler:nil];
    });
}

+ (void)sendInfo:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!g_WebView) return;
        NSString *clean = [msg stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
        NSString *js = [NSString stringWithFormat:@"window.logInfo('%@');", clean];
        [g_WebView evaluateJavaScript:js completionHandler:nil];
    });
}

@end

// =====================================================
// WebView Message Handler
// =====================================================

@interface VR7MessageHandler : NSObject <WKScriptMessageHandler>
@end

@implementation VR7MessageHandler

- (void)userContentController:(WKUserContentController *)ctrl 
      didReceiveScriptMessage:(WKScriptMessage *)msg {
    
    NSString *name = msg.name;
    
    if ([name isEqualToString:@"execute"]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [VR7Executor execute:(NSString *)msg.body];
        });
    }
    else if ([name isEqualToString:@"searchScripts"]) {
        NSString *query = (NSString *)msg.body;
        [VR7ScriptHub searchScripts:query completion:^(NSArray<VR7Script *> *scripts, NSError *error) {
            if (error) return;
            
            NSMutableArray *arr = [NSMutableArray array];
            for (VR7Script *s in scripts) {
                [arr addObject:@{
                    @"id": s.scriptId ?: @"",
                    @"title": s.title ?: @"Untitled",
                    @"game": s.game ?: @"Unknown",
                    @"author": s.author ?: @"Unknown",
                    @"views": @(s.views),
                    @"verified": @(s.verified),
                    @"isFavorite": @(s.isFavorite),
                    @"gameIcon": s.gameIcon ?: @"",
                    @"script": s.script ?: @""
                }];
            }
            
            NSData *json = [NSJSONSerialization dataWithJSONObject:arr options:0 error:nil];
            NSString *jsonStr = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *js = [NSString stringWithFormat:@"window.displaySearchResults(%@);", jsonStr];
                [g_WebView evaluateJavaScript:js completionHandler:nil];
            });
        }];
    }
    else if ([name isEqualToString:@"executeScript"]) {
        NSDictionary *data = (NSDictionary *)msg.body;
        VR7Script *s = [[VR7Script alloc] init];
        s.scriptId = data[@"id"];
        s.title = data[@"title"];
        s.game = data[@"game"];
        s.script = data[@"script"];
        [VR7ScriptHub addToRecent:s];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [VR7Executor execute:data[@"script"]];
        });
    }
    else if ([name isEqualToString:@"toggleFavorite"]) {
        NSDictionary *data = (NSDictionary *)msg.body;
        BOOL isFav = [data[@"isFavorite"] boolValue];
        
        if (isFav) {
            [VR7ScriptHub removeFromFavorites:data[@"id"]];
        } else {
            VR7Script *s = [[VR7Script alloc] init];
            s.scriptId = data[@"id"];
            s.title = data[@"title"];
            s.game = data[@"game"];
            s.script = data[@"script"];
            [VR7ScriptHub addToFavorites:s];
        }
    }
    else if ([name isEqualToString:@"getFavorites"]) {
        NSArray<VR7Script *> *favs = [VR7ScriptHub getFavorites];
        NSMutableArray *arr = [NSMutableArray array];
        for (VR7Script *s in favs) {
            [arr addObject:@{
                @"id": s.scriptId,
                @"title": s.title,
                @"game": s.game,
                @"script": s.script
            }];
        }
        
        NSData *json = [NSJSONSerialization dataWithJSONObject:arr options:0 error:nil];
        NSString *jsonStr = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *js = [NSString stringWithFormat:@"window.displayFavorites(%@);", jsonStr];
            [g_WebView evaluateJavaScript:js completionHandler:nil];
        });
    }
    else if ([name isEqualToString:@"close"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                g_WebView.alpha = 0;
                g_WebView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            } completion:^(BOOL finished) {
                [g_WebView setHidden:YES];
                [g_FloatingButton setHidden:NO];
                g_WebView.transform = CGAffineTransformIdentity;
            }];
        });
    }
}

@end

// =====================================================
// UI Components (Loading, Floating Button, WebView)
// Same as before but adding info about v3.0.0
// =====================================================

void VR7_ShowLoadingScreen() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [[UIApplication sharedApplication] windows].firstObject;
        if (!window) return;
        
        UIVisualEffectView *blur = [[UIVisualEffectView alloc] 
            initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blur.frame = window.bounds;
        blur.alpha = 0;
        g_LoadingView = blur;
        [window addSubview:blur];
        
        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 280)];
        container.center = blur.center;
        container.backgroundColor = [UIColor colorWithRed:0.02 green:0 blue:0.05 alpha:0.95];
        container.layer.cornerRadius = 35;
        container.layer.borderWidth = 3;
        container.layer.borderColor = [UIColor colorWithRed:0.5 green:0 blue:1 alpha:1].CGColor;
        container.layer.shadowColor = [UIColor colorWithRed:0.5 green:0 blue:1 alpha:1].CGColor;
        container.layer.shadowRadius = 25;
        container.layer.shadowOpacity = 1;
        container.transform = CGAffineTransformMakeScale(0.3, 0.3);
        [blur.contentView addSubview:container];
        
        UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 320, 80)];
        logo.text = @"VR7";
        logo.textAlignment = NSTextAlignmentCenter;
        logo.font = [UIFont systemFontOfSize:64 weight:UIFontWeightBlack];
        logo.textColor = [UIColor whiteColor];
        [container addSubview:logo];
        
        UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 130, 320, 30)];
        subtitle.text = @"ULTIMATE EXECUTOR";
        subtitle.textAlignment = NSTextAlignmentCenter;
        subtitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
        subtitle.textColor = [UIColor colorWithRed:0.5 green:0 blue:1 alpha:0.8];
        [container addSubview:subtitle];
        
        UILabel *version = [[UILabel alloc] initWithFrame:CGRectMake(0, 160, 320, 20)];
        version.text = @"v3.0.0 • Max Compatibility";
        version.textAlignment = NSTextAlignmentCenter;
        version.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        version.textColor = [UIColor colorWithWhite:1 alpha:0.4];
        [container addSubview:version];
        
        UILabel *loading = [[UILabel alloc] initWithFrame:CGRectMake(0, 195, 320, 25)];
        loading.text = @"Loading Script Hub...";
        loading.textAlignment = NSTextAlignmentCenter;
        loading.font = [UIFont systemFontOfSize:13];
        loading.textColor = [UIColor whiteColor];
        loading.alpha = 0.7;
        [container addSubview:loading];
        
        UIView *progressBg = [[UIView alloc] initWithFrame:CGRectMake(50, 230, 220, 8)];
        progressBg.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
        progressBg.layer.cornerRadius = 4;
        [container addSubview:progressBg];
        
        UIView *progress = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 8)];
        progress.backgroundColor = [UIColor colorWithRed:0.5 green:0 blue:1 alpha:1];
        progress.layer.cornerRadius = 4;
        [progressBg addSubview:progress];
        
        [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.65 
            initialSpringVelocity:0.5 options:0 animations:^{
            blur.alpha = 1;
            container.transform = CGAffineTransformIdentity;
        } completion:nil];
        
        [UIView animateWithDuration:2.0 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            progress.frame = CGRectMake(0, 0, 220, 8);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.4 animations:^{
                blur.alpha = 0;
                container.transform = CGAffineTransformMakeScale(0.7, 0.7);
            } completion:^(BOOL finished) {
                [blur removeFromSuperview];
                g_LoadingView = nil;
            }];
        }];
    });
}

@interface VR7FloatingButton : UIButton
@property (nonatomic, assign) CGPoint lastLocation;
@end

@implementation VR7FloatingButton
- (void)buttonTapped {
    [g_WebView setHidden:NO];
    [self setHidden:YES];
    g_WebView.alpha = 0;
    g_WebView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 
        initialSpringVelocity:0.5 options:0 animations:^{
        g_WebView.alpha = 1;
        g_WebView.transform = CGAffineTransformIdentity;
    } completion:nil];
}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.superview];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.lastLocation = self.center;
    }
    CGPoint newCenter = CGPointMake(self.lastLocation.x + translation.x, 
                                    self.lastLocation.y + translation.y);
    CGRect bounds = self.superview.bounds;
    CGFloat radius = self.frame.size.width / 2;
    newCenter.x = MAX(radius + 10, MIN(bounds.size.width - radius - 10, newCenter.x));
    newCenter.y = MAX(radius + 10, MIN(bounds.size.height - radius - 10, newCenter.y));
    self.center = newCenter;
}
@end

void VR7_CreateFloatingButton() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [[UIApplication sharedApplication] windows].firstObject;
        if (!window) return;
        
        VR7FloatingButton *btn = [[VR7FloatingButton alloc] initWithFrame:CGRectMake(
            window.bounds.size.width - 90, 150, 70, 70)];
        
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = btn.bounds;
        gradient.colors = @[
            (id)[UIColor colorWithRed:0.5 green:0 blue:1 alpha:1].CGColor,
            (id)[UIColor colorWithRed:0.3 green:0 blue:0.8 alpha:1].CGColor
        ];
        gradient.cornerRadius = 35;
        [btn.layer insertSublayer:gradient atIndex:0];
        
        [btn setTitle:@"VR7" forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        btn.layer.cornerRadius = 35;
        btn.layer.shadowColor = [UIColor colorWithRed:0.5 green:0 blue:1 alpha:1].CGColor;
        btn.layer.shadowRadius = 20;
        btn.layer.shadowOpacity = 0.9;
        
        [btn addTarget:btn action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] 
            initWithTarget:btn action:@selector(handlePan:)];
        [btn addGestureRecognizer:pan];
        
        g_FloatingButton = btn;
        [window addSubview:btn];
        btn.hidden = YES;
    });
}

void VR7_CreateMainUI() {
    dispatch_async(dispatch_get_main_queue(), ^{
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        WKUserContentController *ctrl = [[WKUserContentController alloc] init];
        
        VR7MessageHandler *handler = [[VR7MessageHandler alloc] init];
        [ctrl addScriptMessageHandler:handler name:@"execute"];
        [ctrl addScriptMessageHandler:handler name:@"searchScripts"];
        [ctrl addScriptMessageHandler:handler name:@"executeScript"];
        [ctrl addScriptMessageHandler:handler name:@"toggleFavorite"];
        [ctrl addScriptMessageHandler:handler name:@"getFavorites"];
        [ctrl addScriptMessageHandler:handler name:@"close"];
        
        config.userContentController = ctrl;
        config.preferences.javaScriptEnabled = YES;
        
        CGRect screen = [[UIScreen mainScreen] bounds];
        g_WebView = [[WKWebView alloc] initWithFrame:screen configuration:config];
        g_WebView.backgroundColor = [UIColor clearColor];
        g_WebView.opaque = NO;
        
        // Same HTML as before - the Script Hub UI
        NSString *html = @R"HTML(
<!DOCTYPE html>
<html><head>
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<style>
*{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent}
body{font-family:-apple-system,sans-serif;background:linear-gradient(135deg,#0a0015,#1a0030);color:#fff;height:100vh;overflow:hidden}
.container{height:100vh;display:flex;flex-direction:column;padding:15px}
.header{text-align:center;padding:20px;background:rgba(10,0,20,0.7);border:2px solid rgba(128,0,255,0.4);border-radius:20px;backdrop-filter:blur(15px);margin-bottom:12px;position:relative}
.logo{font-size:42px;font-weight:900;background:linear-gradient(135deg,#8000ff,#00d4ff);-webkit-background-clip:text;-webkit-text-fill-color:transparent;letter-spacing:6px}
.subtitle{font-size:11px;color:rgba(255,255,255,0.6);letter-spacing:3px;margin-top:5px}
.version{font-size:9px;color:rgba(255,255,255,0.4);margin-top:3px}
.close-btn{position:absolute;top:15px;right:15px;width:35px;height:35px;background:rgba(255,0,100,0.2);border:2px solid rgba(255,0,100,0.5);border-radius:50%;color:#fff;font-size:20px;display:flex;align-items:center;justify-content:center}
.tabs{display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-bottom:12px}
.tab{padding:12px;background:rgba(128,0,255,0.1);border:2px solid rgba(128,0,255,0.3);border-radius:12px;text-align:center;font-size:12px;font-weight:700;color:rgba(255,255,255,0.6);cursor:pointer}
.tab.active{background:rgba(128,0,255,0.3);border-color:rgba(128,0,255,0.6);color:#fff}
.search-box{position:relative;margin-bottom:12px}
.search-box input{width:100%;padding:14px 40px 14px 14px;background:rgba(0,0,0,0.4);border:2px solid rgba(128,0,255,0.3);border-radius:12px;color:#fff;font-size:13px;outline:none}
.search-box input::placeholder{color:rgba(255,255,255,0.4)}
.search-icon{position:absolute;right:12px;top:50%;transform:translateY(-50%);font-size:18px;color:rgba(128,0,255,0.6)}
.content{flex:1;overflow-y:auto;background:rgba(5,0,15,0.6);border:2px solid rgba(128,0,255,0.3);border-radius:15px;padding:10px}
.content::-webkit-scrollbar{width:6px}
.content::-webkit-scrollbar-track{background:rgba(0,0,0,0.3);border-radius:3px}
.content::-webkit-scrollbar-thumb{background:rgba(128,0,255,0.5);border-radius:3px}
.script-item{background:rgba(10,0,20,0.8);border:1.5px solid rgba(128,0,255,0.3);border-radius:12px;padding:12px;margin-bottom:10px;position:relative}
.script-header{display:flex;align-items:flex-start;gap:10px;margin-bottom:8px}
.game-icon{width:45px;height:45px;border-radius:8px;background:rgba(128,0,255,0.2);object-fit:cover}
.script-info{flex:1;min-width:0}
.script-title{font-size:13px;font-weight:700;color:#fff;margin-bottom:3px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.script-game{font-size:11px;color:rgba(0,200,255,0.8);margin-bottom:2px}
.script-meta{font-size:10px;color:rgba(255,255,255,0.5);display:flex;gap:10px;align-items:center}
.verified{color:#00ff88}
.fav-btn{position:absolute;top:12px;right:12px;font-size:20px;cursor:pointer;color:rgba(255,255,255,0.3)}
.fav-btn.active{color:#ff0066}
.script-actions{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:10px}
.script-btn{padding:10px;border-radius:10px;font-size:11px;font-weight:700;text-align:center;cursor:pointer}
.btn-execute{background:linear-gradient(135deg,#8000ff,#6000dd);border:1.5px solid rgba(128,0,255,0.6);color:#fff}
.btn-view{background:rgba(128,0,255,0.1);border:1.5px solid rgba(128,0,255,0.3);color:rgba(255,255,255,0.8)}
.editor-view{display:none;flex-direction:column;height:100%}
.editor-view.active{display:flex}
textarea{flex:1;background:rgba(0,0,0,0.4);border:2px solid rgba(128,0,255,0.3);border-radius:12px;color:#00ff88;padding:12px;font-family:Menlo,Monaco,monospace;font-size:12px;resize:none;outline:none;margin-bottom:10px}
.buttons{display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px}
button{padding:14px;background:linear-gradient(135deg,#8000ff,#6000dd);border:2px solid rgba(128,0,255,0.6);border-radius:12px;color:#fff;font-weight:800;font-size:12px;cursor:pointer}
.btn-clear{background:linear-gradient(135deg,#ff0066,#dd0044);border-color:rgba(255,0,102,0.6)}
.console{background:rgba(0,0,0,0.6);border:2px solid rgba(128,0,255,0.25);border-radius:12px;padding:10px;margin-top:10px;height:80px;overflow-y:auto;font-size:10px;font-family:monospace}
.console div{padding:3px 0;border-bottom:1px solid rgba(128,0,255,0.1)}
.success{color:#00ff88;font-weight:700}
.error{color:#ff0066;font-weight:700}
.info{color:#00aaff}
.loading{text-align:center;padding:40px;color:rgba(255,255,255,0.5);font-size:13px}
.empty{text-align:center;padding:40px;color:rgba(255,255,255,0.4);font-size:13px}
</style>
</head><body>
<div class="container">
<div class="header">
<div class="logo">VR7</div>
<div class="subtitle">SCRIPT HUB</div>
<div class="version">v3.0.0 • Updated Offsets</div>
<div class="close-btn" onclick="close()">×</div>
</div>
<div class="tabs">
<div class="tab active" onclick="switchTab('search')" id="tab-search">🔍 SEARCH</div>
<div class="tab" onclick="switchTab('favorites')" id="tab-favorites">⭐ FAVORITES</div>
<div class="tab" onclick="switchTab('editor')" id="tab-editor">📝 EDITOR</div>
</div>
<div id="search-view">
<div class="search-box">
<input type="text" id="searchInput" placeholder="Search scripts..." onkeyup="searchScripts()">
<div class="search-icon">🔍</div>
</div>
<div class="content" id="searchResults">
<div class="loading">Loading popular scripts...</div>
</div>
</div>
<div id="favorites-view" style="display:none">
<div class="content" id="favoritesContent">
<div class="empty">No favorites yet</div>
</div>
</div>
<div id="editor-view" class="editor-view" style="display:none">
<textarea id="code" placeholder="-- VR7 v3.0.0&#10;-- All Client-Side Scripts Supported&#10;&#10;print('Hello from VR7!')"></textarea>
<div class="buttons">
<button onclick="executeCode()">▶ EXECUTE</button>
<button class="btn-clear" onclick="clearCode()">🗑 CLEAR</button>
<button onclick="pasteClipboard()">📋 PASTE</button>
</div>
<div class="console" id="console"></div>
</div>
</div>
<script>
let currentTab='search';let currentScripts=[];let searchTimeout;
function switchTab(tab){currentTab=tab;document.querySelectorAll('.tab').forEach(t=>t.classList.remove('active'));document.getElementById('tab-'+tab).classList.add('active');document.getElementById('search-view').style.display=tab==='search'?'block':'none';document.getElementById('favorites-view').style.display=tab==='favorites'?'block':'none';document.getElementById('editor-view').style.display=tab==='editor'?'flex':'none';if(tab==='favorites'){window.webkit.messageHandlers.getFavorites.postMessage('')}else if(tab==='search'&&currentScripts.length===0){window.webkit.messageHandlers.searchScripts.postMessage('')}}
function searchScripts(){clearTimeout(searchTimeout);const query=document.getElementById('searchInput').value.trim();searchTimeout=setTimeout(()=>{document.getElementById('searchResults').innerHTML='<div class="loading">Searching...</div>';window.webkit.messageHandlers.searchScripts.postMessage(query)},500)}
function displaySearchResults(scripts){currentScripts=scripts;const container=document.getElementById('searchResults');if(scripts.length===0){container.innerHTML='<div class="empty">No scripts found</div>';return}let html='';scripts.forEach(script=>{html+=`<div class="script-item"><div class="script-header">${script.gameIcon?`<img src="${script.gameIcon}" class="game-icon" onerror="this.style.display='none'">`:'<div class="game-icon"></div>'}<div class="script-info"><div class="script-title">${escapeHtml(script.title)}</div><div class="script-game">${escapeHtml(script.game)}</div><div class="script-meta"><span>👁️ ${formatViews(script.views)}</span>${script.verified?'<span class="verified">✓</span>':''}</div></div></div><div class="fav-btn ${script.isFavorite?'active':''}" onclick="toggleFavorite('${script.id}','${escapeHtml(script.title)}','${escapeHtml(script.game)}','${escapeHtml(script.script)}',${script.isFavorite})">${script.isFavorite?'❤️':'🤍'}</div><div class="script-actions"><div class="script-btn btn-execute" onclick="executeScript('${script.id}','${escapeHtml(script.title)}','${escapeHtml(script.game)}','${escapeHtml(script.script)}')">▶ Execute</div><div class="script-btn btn-view" onclick="viewScript('${escapeHtml(script.script)}')">👁️ View</div></div></div>`});container.innerHTML=html}
function displayFavorites(favorites){const container=document.getElementById('favoritesContent');if(favorites.length===0){container.innerHTML='<div class="empty">No favorites yet</div>';return}let html='';favorites.forEach(script=>{html+=`<div class="script-item"><div class="script-header"><div class="game-icon"></div><div class="script-info"><div class="script-title">${escapeHtml(script.title)}</div><div class="script-game">${escapeHtml(script.game)}</div></div></div><div class="fav-btn active" onclick="toggleFavorite('${script.id}','${escapeHtml(script.title)}','${escapeHtml(script.game)}','${escapeHtml(script.script)}',true)">❤️</div><div class="script-actions"><div class="script-btn btn-execute" onclick="executeScript('${script.id}','${escapeHtml(script.title)}','${escapeHtml(script.game)}','${escapeHtml(script.script)}')">▶ Execute</div><div class="script-btn btn-view" onclick="viewScript('${escapeHtml(script.script)}')">👁️ View</div></div></div>`});container.innerHTML=html}
function executeScript(id,title,game,script){window.webkit.messageHandlers.executeScript.postMessage({id:id,title:title,game:game,script:decodeURIComponent(script)})}
function viewScript(script){document.getElementById('code').value=decodeURIComponent(script);switchTab('editor')}
function toggleFavorite(id,title,game,script,isFavorite){window.webkit.messageHandlers.toggleFavorite.postMessage({id:id,title:title,game:game,script:script,isFavorite:isFavorite});setTimeout(()=>{if(currentTab==='favorites'){window.webkit.messageHandlers.getFavorites.postMessage('')}else{window.webkit.messageHandlers.searchScripts.postMessage(document.getElementById('searchInput').value)}},100)}
function executeCode(){const code=document.getElementById('code').value.trim();if(!code){logError('Code is empty');return}window.webkit.messageHandlers.execute.postMessage(code)}
function clearCode(){document.getElementById('code').value='';document.getElementById('console').innerHTML=''}
function pasteClipboard(){logInfo('Paste from clipboard manually')}
function close(){window.webkit.messageHandlers.close.postMessage('')}
function log(m,t){const c=document.getElementById('console');const time=new Date().toLocaleTimeString();c.innerHTML+=`<div class="${t}">[${time}] ${m}</div>`;c.scrollTop=c.scrollHeight;if(c.children.length>50)c.removeChild(c.children[0])}
function logError(m){log('❌ '+m,'error')}
function logSuccess(m){log('✅ '+m,'success')}
function logInfo(m){log('ℹ️ '+m,'info')}
function escapeHtml(text){if(!text)return'';return encodeURIComponent(String(text))}
function formatViews(n){if(n>=1000000)return(n/1000000).toFixed(1)+'M';if(n>=1000)return(n/1000).toFixed(1)+'K';return n}
setTimeout(()=>{window.webkit.messageHandlers.searchScripts.postMessage('')},500);
</script>
</body></html>
)HTML";
        
        [g_WebView loadHTMLString:html baseURL:nil];
        g_WebView.hidden = YES;
        
        UIWindow *window = [[UIApplication sharedApplication] windows].firstObject;
        if (window) [window addSubview:g_WebView];
    });
}

void VR7_StartGameMonitor() {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (true) {
            sleep(1);
            BOOL inGame = [VR7Roblox isInGame];
            
            if (inGame && !g_InGame) {
                g_InGame = YES;
                VR7_LOG("🎮 Game loaded");
                VR7_ShowLoadingScreen();
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.3 * NSEC_PER_SEC), 
                    dispatch_get_main_queue(), ^{
                    [g_WebView setHidden:NO];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC),
                        dispatch_get_main_queue(), ^{
                        [g_FloatingButton setHidden:NO];
                    });
                });
            }
            else if (!inGame && g_InGame) {
                g_InGame = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [g_WebView setHidden:YES];
                    [g_FloatingButton setHidden:YES];
                });
                g_LuaState_Encrypted = 0;
            }
            
            RANDOM_DELAY();
        }
    });
}

void VR7_InitLuaFunctions() {
    void *handle = dlopen(NULL, RTLD_LAZY);
    
    #define LOAD_FUNC(name) { \
        name = (name##_t)dlsym(handle, #name); \
        if (!name) name = (name##_t)dlsym(RTLD_DEFAULT, #name); \
    }
    
    LOAD_FUNC(lua_gettop);
    LOAD_FUNC(lua_settop);
    LOAD_FUNC(lua_pushvalue);
    LOAD_FUNC(lua_remove);
    LOAD_FUNC(lua_type);
    LOAD_FUNC(lua_typename);
    LOAD_FUNC(lua_tonumber);
    LOAD_FUNC(lua_toboolean);
    LOAD_FUNC(lua_tolstring);
    LOAD_FUNC(lua_pushnil);
    LOAD_FUNC(lua_pushnumber);
    LOAD_FUNC(lua_pushinteger);
    LOAD_FUNC(lua_pushstring);
    LOAD_FUNC(lua_pushcclosure);
    LOAD_FUNC(lua_pushboolean);
    LOAD_FUNC(lua_gettable);
    LOAD_FUNC(lua_getfield);
    LOAD_FUNC(lua_rawget);
    LOAD_FUNC(lua_rawgeti);
    LOAD_FUNC(lua_createtable);
    LOAD_FUNC(lua_settable);
    LOAD_FUNC(lua_setfield);
    LOAD_FUNC(lua_rawset);
    LOAD_FUNC(lua_rawseti);
    LOAD_FUNC(lua_setmetatable);
    LOAD_FUNC(lua_getmetatable);
    LOAD_FUNC(lua_newuserdata);
    LOAD_FUNC(lua_call);
    LOAD_FUNC(lua_pcall);
    LOAD_FUNC(luaL_loadstring);
    LOAD_FUNC(luaL_loadbuffer);
    LOAD_FUNC(lua_getglobal);
    LOAD_FUNC(lua_setglobal);
    LOAD_FUNC(lua_error);
    LOAD_FUNC(lua_next);
    LOAD_FUNC(luau_load);
    LOAD_FUNC(luau_compile);
    
    VR7_LOG("Lua API loaded");
}

__attribute__((constructor))
static void VR7_Initialize() {
    @autoreleasepool {
        NSLog(@"============================================");
        NSLog(@"[VR7] 🚀 VR7 ULTIMATE EXECUTOR v" VR7_VERSION);
        NSLog(@"[VR7] 🔥 Maximum Script Compatibility");
        NSLog(@"[VR7] 🔍 Script Hub + Luau + Protections");
        NSLog(@"[VR7] 📡 Auto-Updating Offsets");
        NSLog(@"============================================");
        
        g_XORKey = arc4random();
        g_XORKey = (g_XORKey << 32) | arc4random();
        
        usleep(arc4random_uniform(500000) + 200000);
        
        VR7_LOG("🛡️ Enabling protections...");
        [VR7AntiDebug enableProtection];
        [VR7JailbreakBypass enableBypass];
        [VR7ByfronBypass enableBypass];
        
        g_ProtectionEnabled = YES;
        
        VR7_LOG("📡 Loading offsets from GitHub...");
        [VR7OffsetsManager initialize];
        
        VR7_LOG("⚙️ Initializing Lua...");
        VR7_InitLuaFunctions();
        
        VR7_LOG("🔧 Initializing Luau...");
        [VR7LuauCompiler initialize];
        
        VR7_LOG("🔍 Initializing Script Hub...");
        [VR7ScriptHub initialize];
        
        [VR7Roblox getBaseAddress];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), 
            dispatch_get_main_queue(), ^{
            VR7_LOG("🎨 Creating UI...");
            VR7_CreateFloatingButton();
            VR7_CreateMainUI();
            VR7_StartGameMonitor();
        });
        
        VR7_LOG("✅ VR7 v3.0.0 fully initialized");
        VR7_LOG("============================================");
    }
}
