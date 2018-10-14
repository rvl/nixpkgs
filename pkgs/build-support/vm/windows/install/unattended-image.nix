{ stdenv, writeText, dosfstools, mtools }:

{ productKey ? null
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

  # Migration of Unattend.txt settings
  # https://msdn.microsoft.com/en-us/library/windows/hardware/dn923100(v=vs.85).aspx
  win10Unattended = writeText "Autounattend.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend">
        <settings pass="specialize">
            <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <AutoLogon>
                    <Password>
                        <Value>nopasswd</Value>
                        <PlainText>true</PlainText>
                    </Password>
                    <Enabled>true</Enabled>
                    <LogonCount>2</LogonCount>
                    <Username>Administrator</Username>
                </AutoLogon>
                <ComputerName>*</ComputerName>
                <OOBE>
                   <HideEULAPage>true</HideEULAPage>
                   <NetworkLocation>Other</NetworkLocation>
                   <ProtectYourPC>3</ProtectYourPC>
                   <SkipMachineOOBE>true</SkipMachineOOBE>
                   <SkipUserOOBE>true</SkipUserOOBE>
                </OOBE>

                <FirstLogonCommands>
                   <SynchronousCommand wcm:action="add">
                      <CommandLine>${stdenv.lib.concatStringsSep " " afterSetup}</CommandLine>
                      <Description>cygwin setup</Description>
                      <Order>1</Order>
                   </SynchronousCommand>
                   <SynchronousCommand wcm:action="add">
                      <CommandLine>${cygwinRoot}\bin\bash -l ${shExecAfterwards}</CommandLine>
                      <Description>bash command</Description>
                      <Order>2</Order>
                   </SynchronousCommand>
                </FirstLogonCommands>
            </component>

            <!--
            <component name="Networking-MPSSVC-Svc" language="neutral" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" processorarchitecture="amd64" publickeytoken="31bf3856ad364e35" versionscope="nonSxS">
              <DomainProfile_EnableFirewall>false</DomainProfile_EnableFirewall>
              <PrivateProfile_EnableFirewall>false</PrivateProfile_EnableFirewall>
              <PublicProfile_EnableFirewall>false</PublicProfile_EnableFirewall>
            </component>

            <component name="Microsoft-Windows-UnattendedJoin" language="neutral" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" processorarchitecture="amd64" publickeytoken="31bf3856ad364e35" versionscope="nonSxS">
              <Identification>
                <JoinWorkgroup>cygwin</JoinWorkgroup>
                <UnsecureJoin>true</UnsecureJoin>
              </Identification>
            </component>
            -->
        </settings>

        <settings pass="windowsPE">
            <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <DiskConfiguration>

                  <Disk wcm:action="add">
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                    <CreatePartitions>
                      <!-- System partition -->
                      <CreatePartition wcm:action="add">
                        <Order>1</Order>
                        <Type>Primary</Type>
                        <Size>350</Size>
                      </CreatePartition>

                      <!-- Windows partition -->
                      <CreatePartition wcm:action="add">
                        <Order>2</Order>
                        <Type>Primary</Type>
                        <Extend>true</Extend>
                      </CreatePartition>
                    </CreatePartitions>

                    <ModifyPartitions>
                      <!-- System partition -->
                      <ModifyPartition wcm:action="add">
                        <Order>1</Order>
                        <PartitionID>1</PartitionID>
                        <Label>System</Label>
                        <Letter>S</Letter>
                        <Format>NTFS</Format>
                        <Active>true</Active>
                      </ModifyPartition>

                      <!-- Windows partition -->
                      <ModifyPartition wcm:action="add">
                        <Order>2</Order>
                        <PartitionID>2</PartitionID>
                        <Label>Windows</Label>
                        <Letter>C</Letter>
                        <Format>NTFS</Format>
                      </ModifyPartition>
                    </ModifyPartitions>
                  </Disk>
                  <WillShowUI>OnError</WillShowUI>
                </DiskConfiguration>

                <ImageInstall>
                  <OSImage>
                    <InstallTo>
                      <DiskID>0</DiskID>
                      <PartitionID>2</PartitionID>
                    </InstallTo>
                    <WillShowUI>Never</WillShowUI>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/IMAGE/NAME</Key>
                            <Value>Windows 10 Pro</Value>
                        </MetaData>
                    </InstallFrom>
                  </OSImage>
                </ImageInstall>

                <UserData>
                    <ProductKey>
                        <Key>${toString productKey}</Key>
                        <WillShowUI>Never</WillShowUI>
                    </ProductKey>
                    <AcceptEula>true</AcceptEula>
                </UserData>
                <EnableNetwork>false</EnableNetwork>
                <EnableFirewall>false</EnableFirewall>
            </component>
            <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <SetupUILanguage>
                    <UILanguage>en-us</UILanguage>
                </SetupUILanguage>
                <UILanguage>en-us</UILanguage>
                <UILanguageFallback>en-US</UILanguageFallback>
                <InputLocale>0409:00000409</InputLocale>
                <SystemLocale>en-US</SystemLocale>
                <UserLocale>en-US</UserLocale>
            </component>

            <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
              <Interfaces>
                <Interface wcm:action="add">
                    <Ipv4Settings>
                        <DhcpEnabled>false</DhcpEnabled>
                    </Ipv4Settings>
                    <Identifier>Local Area Connection</Identifier>
                    <UnicastIpAddresses>
                        <IpAddress wcm:action="add" wcm:keyValue="1">192.168.0.1/24</IpAddress>
                    </UnicastIpAddresses>
                </Interface>
              </Interfaces>
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
  passthru = {
    xml = win10Unattended;
  };
}
