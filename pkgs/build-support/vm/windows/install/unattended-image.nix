{ stdenv, writeText, dosfstools, mtools }:

{ productKey
, shExecAfterwards ? "E:\\bootstrap.sh"
, cygwinRoot ? "C:\\cygwin"
, cygwinSetup ? "E:\\setup.exe"
, cygwinRepository ? "E:\\"
, cygwinPackages ? [ "openssh" ]
}:

let
  afterSetup = [
    cygwinSetup
    "-L -n -q"
    "-l ${cygwinRepository}"
    "-R ${cygwinRoot}"
    "-C base"
  ] ++ map (p: "-P ${p}") cygwinPackages;

  winXpUnattended = writeText "winnt.sif" ''
    [Data]
    AutoPartition = 1
    AutomaticUpdates = 0
    MsDosInitiated = 0
    UnattendedInstall = Yes

    [Unattended]
    DUDisable = Yes
    DriverSigningPolicy = Ignore
    Hibernation = No
    OemPreinstall = No
    OemSkipEula = Yes
    Repartition = Yes
    TargetPath = \WINDOWS
    UnattendMode = FullUnattended
    UnattendSwitch = Yes
    WaitForReboot = No

    [GuiUnattended]
    AdminPassword = "nopasswd"
    AutoLogon = Yes
    AutoLogonCount = 1
    OEMSkipRegional = 1
    OemSkipWelcome = 1
    ServerWelcome = No
    TimeZone = 85

    [UserData]
    ComputerName = "cygwin"
    FullName = "cygwin"
    OrgName = ""
    ProductKey = "${productKey}"

    [Networking]
    InstallDefaultComponents = Yes

    [Identification]
    JoinWorkgroup = cygwin

    [NetAdapters]
    PrimaryAdapter = params.PrimaryAdapter

    [params.PrimaryAdapter]
    InfID = *

    [params.MS_MSClient]

    [NetProtocols]
    MS_TCPIP = params.MS_TCPIP

    [params.MS_TCPIP]
    AdapterSections=params.MS_TCPIP.PrimaryAdapter

    [params.MS_TCPIP.PrimaryAdapter]
    DHCP = No
    IPAddress = 192.168.0.1
    SpecificTo = PrimaryAdapter
    SubnetMask = 255.255.255.0
    WINS = No

    ; Turn off all components
    [Components]
    ${stdenv.lib.concatMapStrings (comp: "${comp} = Off\n") [
      "AccessOpt" "Appsrv_console" "Aspnet" "BitsServerExtensionsISAPI"
      "BitsServerExtensionsManager" "Calc" "Certsrv" "Certsrv_client"
      "Certsrv_server" "Charmap" "Chat" "Clipbook" "Cluster" "Complusnetwork"
      "Deskpaper" "Dialer" "Dtcnetwork" "Fax" "Fp_extensions" "Fp_vdir_deploy"
      "Freecell" "Hearts" "Hypertrm" "IEAccess" "IEHardenAdmin" "IEHardenUser"
      "Iis_asp" "Iis_common" "Iis_ftp" "Iis_inetmgr" "Iis_internetdataconnector"
      "Iis_nntp" "Iis_serversideincludes" "Iis_smtp" "Iis_webdav" "Iis_www"
      "Indexsrv_system" "Inetprint" "Licenseserver" "Media_clips" "Media_utopia"
      "Minesweeper" "Mousepoint" "Msmq_ADIntegrated" "Msmq_Core"
      "Msmq_HTTPSupport" "Msmq_LocalStorage" "Msmq_MQDSService"
      "Msmq_RoutingSupport" "Msmq_TriggersService" "Msnexplr" "Mswordpad"
      "Netcis" "Netoc" "OEAccess" "Objectpkg" "Paint" "Pinball" "Pop3Admin"
      "Pop3Service" "Pop3Srv" "Rec" "Reminst" "Rootautoupdate" "Rstorage" "SCW"
      "Sakit_web" "Solitaire" "Spider" "TSWebClient" "Templates"
      "TerminalServer" "UDDIAdmin" "UDDIDatabase" "UDDIWeb" "Vol" "WMAccess"
      "WMPOCM" "WbemMSI" "Wms" "Wms_admin_asp" "Wms_admin_mmc" "Wms_isapi"
      "Wms_server" "Zonegames"
    ]}

    [WindowsFirewall]
    Profiles = WindowsFirewall.TurnOffFirewall

    [WindowsFirewall.TurnOffFirewall]
    Mode = 0

    [SetupParams]
    UserExecute = "${stdenv.lib.concatStringsSep " " afterSetup}"

    [GuiRunOnce]
    Command0 = "${cygwinRoot}\bin\bash -l ${shExecAfterwards}"
  '';

  # https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-automation-overview#implicit-answer-file-search-order
  # https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/update-windows-settings-and-scripts-create-your-own-answer-file-sxs
  # Migration of Unattend.txt settings
  # https://msdn.microsoft.com/en-us/library/windows/hardware/dn923100(v=vs.85).aspx
  win10Unattended = writeText "Autounattend.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend">
        <settings pass="specialize">
            <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <AutoLogon>
                    <Password>
                        <Value><!-- INSERT ADMINISTRATOR PASSWORD HERE --></Value>
                        <PlainText>true</PlainText>
                    </Password>
                    <Enabled>true</Enabled>
                    <LogonCount>2</LogonCount>
                    <Username>Administrator</Username>
                </AutoLogon>
                <ComputerName>*</ComputerName>
            </component>
        </settings>
        <settings pass="windowsPE">
            <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <DiskConfiguration>
                    <Disk wcm:action="add">
                        <CreatePartitions>
                            <CreatePartition wcm:action="add">
                                <Order>1</Order>
                                <Size>500</Size>
                                <Type>Primary</Type>
                            </CreatePartition>
                            <CreatePartition wcm:action="add">
                                <Order>2</Order>
                                <Size>100</Size>
                                <Type>EFI</Type>
                            </CreatePartition>
                            <CreatePartition wcm:action="add">
                                <Order>3</Order>
                                <Size>16</Size>
                                <Type>MSR</Type>
                            </CreatePartition>
                            <CreatePartition wcm:action="add">
                                <Order>4</Order>
                                <Extend>true</Extend>
                                <Type>Primary</Type>
                            </CreatePartition>
                        </CreatePartitions>
                        <ModifyPartitions>
                            <ModifyPartition wcm:action="add">
                                <Order>1</Order>
                                <PartitionID>1</PartitionID>
                                <Label>WinRE</Label>
                                <Format>NTFS</Format>
                                <TypeID>de94bba4-06d1-4d40-a16a-bfd50179d6ac</TypeID>
                            </ModifyPartition>
                            <ModifyPartition wcm:action="add">
                                <Order>2</Order>
                                <PartitionID>2</PartitionID>
                                <Label>System</Label>
                                <Format>FAT32</Format>
                            </ModifyPartition>
                            <ModifyPartition wcm:action="add">
                                <Order>3</Order>
                                <PartitionID>3</PartitionID>
                            </ModifyPartition>
                            <ModifyPartition wcm:action="add">
                                <Order>4</Order>
                                <PartitionID>4</PartitionID>
                                <Label>Windows</Label>
                                <Format>NTFS</Format>
                            </ModifyPartition>
                        </ModifyPartitions>
                        <DiskID>0</DiskID>
                        <WillWipeDisk>true</WillWipeDisk>
                    </Disk>
                    <WillShowUI>OnError</WillShowUI>
                </DiskConfiguration>
                <ImageInstall>
                    <OSImage>
                        <InstallTo>
                            <DiskID>0</DiskID>
                            <PartitionID>4</PartitionID>
                        </InstallTo>
                        <WillShowUI>Never</WillShowUI>
                        <InstallFrom>
                            <MetaData wcm:action="add">
                                <Key>/IMAGE/NAME</Key>
                                <Value><!--REPLACE WITH PRODUCT NAME--></Value>
                            </MetaData>
                        </InstallFrom>
                    </OSImage>
                </ImageInstall>
                <UserData>
                    <ProductKey>
                        <Key><!--REPLACE WITH PRODUCT KEY--></Key>
                        <WillShowUI>Never</WillShowUI>
                    </ProductKey>
                    <AcceptEula>true</AcceptEula>
                </UserData>
                <EnableNetwork>false</EnableNetwork>
            </component>
            <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <SetupUILanguage>
                    <UILanguage>en-us</UILanguage>
                </SetupUILanguage>
                <UILanguage>en-us</UILanguage>
            </component>
        </settings>
    </unattend>
  '';

in stdenv.mkDerivation {
  name = "unattended-floppy.img";
  buildCommand = ''
    dd if=/dev/zero of="$out" count=1440 bs=1024
    ${dosfstools}/sbin/mkfs.msdos "$out"
    ${mtools}/bin/mcopy -i "$out" "${win10Unattended}" ::Autounattend.xml
  '';
}
