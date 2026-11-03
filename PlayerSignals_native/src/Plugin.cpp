#include <RE/Skyrim.h>
#include <SKSE/SKSE.h>

#include <Windows.h>

#include <cstdint>
#include <mutex>
#include <thread>

namespace logger = SKSE::log;

namespace {
constexpr char kScriptName[] = "PlayerSignals_Native";
constexpr char kVersion[] = "1.0.1";
// Guards key-down/key-up together with the per-code press ticket so an older
// worker can never release a hold that a later press of the same key now owns.
std::mutex g_keyLock;
std::uint32_t g_pressSeq[256]{};

void SendKeyUp(WORD scanCode, DWORD flags, std::int32_t requestedCode)
{
    INPUT input{};
    input.type = INPUT_KEYBOARD;
    input.ki.wScan = scanCode;
    input.ki.dwFlags = flags | KEYEVENTF_KEYUP;
    if (SendInput(1, &input, sizeof(input)) != 1) {
        logger::error("SendRawKey key-up failed: code={}, error={}", requestedCode, GetLastError());
    }
}

void ReleaseIfOwner(WORD scan, DWORD flags, std::int32_t scanCode, std::uint32_t ticket)
{
    std::lock_guard lock(g_keyLock);
    if (g_pressSeq[scanCode] == ticket) {
        SendKeyUp(scan, flags, scanCode);
    } else {
        logger::info("SendRawKey: code={}: skipping key-up owned by a later press", scanCode);
    }
}

std::int32_t GetNativeVersion(RE::StaticFunctionTag*)
{
    return 1;
}

bool SendRawKey(RE::StaticFunctionTag*, std::int32_t scanCode, std::int32_t holdMs)
{
    const HWND foreground = GetForegroundWindow();
    DWORD foregroundProcess = 0;
    if (foreground) {
        GetWindowThreadProcessId(foreground, &foregroundProcess);
    }
    const bool focused = foreground && foregroundProcess == GetCurrentProcessId();

    if (scanCode < 1 || scanCode > 255 || holdMs < 1 || holdMs > 2000) {
        logger::warn("SendRawKey: code={}, result=false, foreground={}: invalid arguments", scanCode, focused);
        return false;
    }
    if (!focused) {
        logger::warn("SendRawKey: code={}, result=false, foreground=false", scanCode);
        return false;
    }

    const WORD scan = static_cast<WORD>(scanCode >= 0x80 ? scanCode & 0x7F : scanCode);
    const DWORD flags = KEYEVENTF_SCANCODE | (scanCode >= 0x80 ? KEYEVENTF_EXTENDEDKEY : 0);
    INPUT input{};
    input.type = INPUT_KEYBOARD;
    input.ki.wScan = scan;
    input.ki.dwFlags = flags;
    std::uint32_t ticket;
    {
        std::lock_guard lock(g_keyLock);
        if (SendInput(1, &input, sizeof(input)) != 1) {
            logger::warn("SendRawKey: code={}, result=false, foreground=true: key-down failed, error={}", scanCode, GetLastError());
            return false;
        }
        ticket = ++g_pressSeq[scanCode];
    }

    std::thread worker;
    try {
        worker = std::thread([scan, flags, holdMs, scanCode, ticket]() {
            Sleep(static_cast<DWORD>(holdMs));
            ReleaseIfOwner(scan, flags, scanCode, ticket);
        });
        worker.detach();
    } catch (...) {
        if (worker.joinable()) {
            worker.join();
        } else {
            ReleaseIfOwner(scan, flags, scanCode, ticket);
        }
        logger::error("SendRawKey: code={}, result=false, foreground=true: worker thread startup failed", scanCode);
        return false;
    }
    logger::info("SendRawKey: code={}, result=true, foreground=true", scanCode);
    return true;
}

bool RegisterNatives(RE::BSScript::IVirtualMachine* vm)
{
    if (!vm) {
        logger::error("PlayerSignals: Papyrus VM unavailable");
        return false;
    }
    vm->RegisterFunction("GetNativeVersion", kScriptName, GetNativeVersion);
    vm->RegisterFunction("SendRawKey", kScriptName, SendRawKey);
    logger::info("PlayerSignals: registered Papyrus natives");
    return true;
}
}

SKSEPluginLoad(const SKSE::LoadInterface* skse)
{
    SKSE::Init(skse);
    SKSE::log::init();
    logger::info("PlayerSignals v{} loading", kVersion);

    const auto papyrus = SKSE::GetPapyrusInterface();
    if (!papyrus || !papyrus->Register(RegisterNatives)) {
        logger::error("PlayerSignals: failed to register Papyrus natives");
        return false;
    }
    logger::info("PlayerSignals loaded successfully");
    return true;
}