
using System.CodeDom;
using System.Runtime.InteropServices;

state("Subnautica", "September 2018")
{
    //player is "Subnautica.exe", 0x142b908, 0x180, 0x128, 0x80, 0x1d0, 0x8, 0x248, ...
    //modules.First() length 23801856
    //bool rocketLaunching: "mono.dll", 0x27EAD8, 0x40, 0x70, 0x50, 0x90, 0x30, 0x8, 0x80;
    //bool introCinematicActive: "Subnautica.exe", 0x142b908, 0x188, 0x150, 0xd0, 0x18, 0x1e8, 0x28, 0x86;
    //bool playerCinematicActive: "Subnautica.exe", 0x142b908, 0x180, 0x128, 0x80, 0x1d0, 0x8, 0x248, 0x240;
    //string128 biomeString: "Subnautica.exe", 0x142b908, 0x180, 0x128, 0x80, 0x1d0, 0x8, 0x248, 0x1d0, 0x14;
}

state("Subnautica", "December 2021")
{
    //player is "UnityPlayer.dll", 0x1690cd0, 0x8, 0x10, 0x30, 0x678, 0x58, 0x188, ...
    //modules.First() length 671744
    //bool rocketLaunching: "UnityPlayer.dll", 0x1678148, 0x40, 0x5f0, 0x424, 0x8, 0xd8, 0x40, 0x80;
    //bool introCinematicActive: "UnityPlayer.dll", 0x16d0400, 0x68, 0x140, 0xa8, 0x18, 0x60, 0x28, 0x86;
    //bool playerCinematicActive: "UnityPlayer.dll", 0x1690cd0, 0x8, 0x10, 0x30, 0x678, 0x58, 0x188, 0x248;
    //string128 biomeString: "UnityPlayer.dll", 0x1690cd0, 0x8, 0x10, 0x30, 0x678, 0x58, 0x188, 0x1d8, 0x14;
}

init
{
    vars.nullptr = new IntPtr((int)IntPtr.Zero);
    int firstModuleSize = modules.First().ModuleMemorySize;
    print("first module is " + firstModuleSize.ToString() + " bytes long");
    //regions dont work in ASL AAAAAAAAAAA

    //CP signatures
    string CPEscapePodSig = "48 B9 ?? ?? ?? ?? ?? ?? ?? ?? 49 BB ?? ?? ?? ?? ?? ?? ?? ?? 41 FF D3 48 8B 45 90 48 8B 75 F8 48 8D 65 00";
    int CPEscapePodOff = 2;
    string CPLaunchStartedSig = "48 B8 ?? ?? ?? ?? ?? ?? ?? ?? 0F B6 00 85 C0 0F 84 ?? ?? ?? ?? F3 0F 10 86";
    int CPLaunchStartedOff = 2;

    //Sept 18 signatures
    string DownEscapePodSig = "48 83 c4 20 b8 ?? ?? ?? ?? 48 89 30 48 8d 65 f0 5f 5e c9 c3";
    int DownEscapePodOff = 5;
    string DownLaunchStartedSig = "b8 ?? ?? ?? ?? 48 0fb6 00 85 c0 0f84 ?? ?? ?? ?? f3 0f10 86";
    int DownLaunchStartedOff = 1;

    //Pointers for scanning
    vars.EscapePodSignaturePointer = vars.nullptr;
    vars.LaunchStartedSignaturePointer = vars.nullptr;


    vars.LaunchStartedOffset;

    switch (firstModuleSize)
    {
        case 23801856:
            version = "September 2018";
            vars.EscapePodSignature = DownEscapePodSig;
            vars.EscapePodOffset = DownEscapePodOff;
            vars.LaunchStartedSignature = DownLaunchStartedSig;
            vars.LaunchStartedOffset = DownLaunchStartedOff;
            break;
        case 671744:
            version = "December 2021";
            vars.EscapePodSignature = CPEscapePodSig;
            vars.EscapePodOffset = CPEscapePodOff;
            vars.LaunchStartedSignature = CPLaunchStartedSig;
            vars.LaunchStartedOffset = CPLaunchStartedOff;
            break;
    }
    print("escape pod offset is " + vars.EscapePodOffset);

    vars.sigScanTokenSource = new CancellationTokenSource();
    vars.sigScanToken = vars.sigScanTokenSource.Token;
    vars.sigScanThread = new Thread(() =>
    {
        print("starting sig scan thread");
        
        var EscapePodTarget = new SigScanTarget(vars.EscapePodOffset, vars.EscapePodSignature);
        var LaunchStartedTarget = new SigScanTarget(vars.LaunchStartedTarget,  vars.LaunchStartedSignature);

        while (!vars.sigScanToken.IsCancellationRequested)
        {
            int p = 0;
            foreach (var page in game.MemoryPages())
            {
                p++;
                if (p % 50 == 0) { Thread.Sleep(100); }
                var scanner = new SignatureScanner(game, page.BaseAddress, (int) page.RegionSize);

                //stop in the middle of foreach if both signatures are found
                if (vars.EscapePodSignaturePointer != vars.nullptr && vars.LaunchStartedSignaturePointer != vars.nullptr)
                {
                    break
                }

                //scanning
                if (vars.EscapePodSignaturePointer == vars.nullptr && (vars.EscapePodSignaturePtr = scanner.Scan(EscapePodTarget)) != vars.nullptr)
                {
                    vars.EscapePodSignaturePointer = scanner.Scan(EscapePodTarget);
                }
                if (vars.LaunchStartedSignaturePointer == vars.nullptr && (vars.LaunchStartedSignaturePointer = scanner.Scan(LaunchStartedTarget)) != vars.nullptr)
                {
                    vars.LaunchStartedSignaturePointer = scanner.Scan(LaunchStartedTarget);
                }
            }
            if (vars.EscapePodSignaturePointer != vars.nullptr && vars.LaunchStartedSignaturePointer != vars.nullptr)
            {
                //deref pointers n stuff
                
                var LaunchStartedAddress = game.ReadPointer(vars.LaunchStartedSignaturePointer);
                vars.LaunchStarted = new new MemoryWatcher<bool>(LaunchStartedAddress)
            }
        }
    });
}

startup
{
    //settings.Add(id (string), default_value (bool), description (string), parent (string))
    settings.Add("start", true, "Split on start");
    settings.Add("end", true, "Split on rocket launch");
    //settings.Add("gunDeactivate", false, "Split on gun deactivation");

}

split
{
   
}

start
{

}

update
{
    //print(modules.First().ModuleMemorySize.ToString());
    //print(modules.First().ToString());
    //print(current.playerCinematicActive.ToString());
    //print(current.biomeString);
    if (settings["end"]) { vars.LaunchStarted.Update(); }
    if (settings["start"]) {}
}