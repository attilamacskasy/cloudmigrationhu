# Unattend.xml – Screenshot‑by‑Screenshot Mapping

This document shows how the generated `unattend.xml` file relates to the `unattend.xml-01.jpg` … `unattend.xml-15.jpg` screenshots in this folder.

The script `Win11-SysprepCleanup.ps1` creates `C:\Windows\System32\Sysprep\unattend.xml` when you run it with:

```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage <en-US|hu-HU>
```

and then calls:

```text
Sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\unattend.xml
```

Below you see each OOBE screen in order (01–15), with the **screenshot**, then the **relevant XML component** that configures or skips that screen.

---

## Screenshot `unattend.xml-01.jpg` – Keyboard layout

![unattend.xml-01](unattend.xml-01.jpg)

Windows 11 OOBE asks: *“Is this the right keyboard layout or input method?”* (Hungarian UI). The first item is the **Hungarian** layout, with other layouts below.

**Relevant XML – language & keyboard**  
Component: `Microsoft-Windows-International-Core` (pass = `oobeSystem`)

```xml
<settings pass="oobeSystem">
  <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
    <InputLocale>hu-HU</InputLocale>        <!-- or en-US -->
    <SystemLocale>hu-HU</SystemLocale>
    <UILanguage>hu-HU</UILanguage>
    <UILanguageFallback>hu-HU</UILanguageFallback>
    <UserLocale>hu-HU</UserLocale>
  </component>
</settings>
```

- `InputLocale` selects this keyboard layout.  
- `SystemLocale` / `UserLocale` control regional formats.  
- `UILanguage` / `UILanguageFallback` control the UI text language.  
- With `UnattendLanguage=hu-HU` or `en-US`, these values are pre‑set and this page is normally skipped.

---

## Screenshot `unattend.xml-02.jpg` – Add second keyboard layout

![unattend.xml-02](unattend.xml-02.jpg)

OOBE asks: *“Do you want to add a second keyboard layout?”* with **Add layout** and **Skip** buttons.

**Relevant XML** – still `Microsoft-Windows-International-Core`

```xml
<InputLocale>hu-HU</InputLocale>
<UserLocale>hu-HU</UserLocale>
```

Because the primary layout is already defined, unattended setup keeps that choice and silently skips this follow‑up screen.

---

## Screenshot `unattend.xml-03.jpg` – License agreement (EULA)

![unattend.xml-03](unattend.xml-03.jpg)

Hungarian license agreement page asking you to review and accept the Microsoft Software License Terms.

**Relevant XML – hide EULA page**  
Component: `Microsoft-Windows-Shell-Setup` (pass = `oobeSystem`)

```xml
<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
  <OOBE>
    <HideEULAPage>true</HideEULAPage>
    ...
  </OOBE>
</component>
```

- `HideEULAPage=true` hides this EULA screen completely when using the unattended file.

---

## Screenshot `unattend.xml-04.jpg` – Device name

![unattend.xml-04](unattend.xml-04.jpg)

Screen asking you to **name the device** (for example `tpl-win-11-v2`) with rules for the computer name.

**Relevant XML** – none directly

The current `unattend.xml` does **not** set the hostname. The closest related metadata is:

```xml
<RegisteredOwner>Administrator</RegisteredOwner>
<RegisteredOrganization>Proxmox</RegisteredOrganization>
<TimeZone>UTC</TimeZone>
```

- These values affect System Properties and time zone, not the device name.  
- Host name is still entered manually or via later automation.

---

## Screenshot `unattend.xml-05.jpg` – Personal vs work/school

![unattend.xml-05](unattend.xml-05.jpg)

OOBE asks: *“How would you like to set up this device?”* with choices for **personal use** or **work / school**.

**Relevant XML – skip account/setup wizard**  
Component: `Microsoft-Windows-Shell-Setup` → `<OOBE>`

```xml
<OOBE>
  <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
  <NetworkLocation>Work</NetworkLocation>
  <SkipUserOOBE>true</SkipUserOOBE>
  <SkipMachineOOBE>true</SkipMachineOOBE>
</OOBE>
```

- `HideOnlineAccountScreens` removes Microsoft‑account‑centric flows.  
- `SkipUserOOBE` and `SkipMachineOOBE` skip this whole experience.  
- `NetworkLocation=Work` matches the intended enterprise / Proxmox template scenario.

---

## Screenshot `unattend.xml-06.jpg` – Local account name

![unattend.xml-06](unattend.xml-06.jpg)

Screen titled *“Who will use this device?”* where you type a local username (for example `localuser`).

**Relevant XML – skip user OOBE**

```xml
<SkipUserOOBE>true</SkipUserOOBE>
```

- The unattended file does not hard‑code a username or password.  
- `SkipUserOOBE=true` prevents this page from being shown; you can create accounts later via automation or manual admin steps.

---

## Screenshot `unattend.xml-07.jpg` – Local account password

![unattend.xml-07](unattend.xml-07.jpg)

OOBE asks you to create an "easy to remember" password for the local user.

**Relevant XML**

```xml
<SkipUserOOBE>true</SkipUserOOBE>
```

- The password wizard is part of user OOBE. Because `SkipUserOOBE=true`, password creation is left to later scripts or cloud-init rather than done here.

---

## Screenshot `unattend.xml-08.jpg` – Security questions

![unattend.xml-08](unattend.xml-08.jpg)

Screen asking you to choose and answer security questions (e.g. *“What was the name of your first pet?”*) for password recovery.

**Relevant XML**

```xml
<SkipUserOOBE>true</SkipUserOOBE>
```

- These questions are another part of user OOBE and are never asked when you skip it.

---

## Screenshot `unattend.xml-09.jpg` – Location services

![unattend.xml-09](unattend.xml-09.jpg)

Privacy screen about allowing **location services** for Microsoft and apps. The **No** option is selected.

**Relevant XML – privacy baseline**

```xml
<OOBE>
  <ProtectYourPC>1</ProtectYourPC>
  <SkipUserOOBE>true</SkipUserOOBE>
</OOBE>
```

- `ProtectYourPC` sets the general privacy/security level.  
- With `SkipUserOOBE`, this location screen is not shown; Windows applies the configured defaults.

---

## Screenshot `unattend.xml-10.jpg` – Find my device

![unattend.xml-10](unattend.xml-10.jpg)

Screen titled *“Track my device”* (Find my device) with **Yes** / **No**; **No** is chosen.

**Relevant XML – hide online account screens**

```xml
<OOBE>
  <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
  <SkipUserOOBE>true</SkipUserOOBE>
</OOBE>
```

- Find‑my‑device depends on signing in with a Microsoft account.  
- Because online‑account screens are hidden and user OOBE is skipped, this page is not presented in unattended runs.

---

## Screenshot `unattend.xml-11.jpg` – Diagnostic data level

![unattend.xml-11](unattend.xml-11.jpg)

Privacy screen titled *“Send diagnostic data to Microsoft”*; the minimal / required level is selected.

**Relevant XML**

```xml
<OOBE>
  <ProtectYourPC>1</ProtectYourPC>
</OOBE>
```

- `ProtectYourPC` defines whether only required or more extensive diagnostics are sent.  
- With unattended setup, this choice is applied automatically and the page is skipped.

---

## Screenshot `unattend.xml-12.jpg` – Improve inking & typing

![unattend.xml-12](unattend.xml-12.jpg)

Screen asking whether to send optional diagnostic data about handwriting and typing to "improve inking & typing"; **No** is selected.

**Relevant XML**

```xml
<OOBE>
  <ProtectYourPC>1</ProtectYourPC>
</OOBE>
```

- This is another optional diagnostics toggle controlled by the same privacy baseline.  
- When using `unattend.xml`, the choice is enforced by XML and this page is not shown.

---

## Screenshot `unattend.xml-13.jpg` – Tailored experiences

![unattend.xml-13](unattend.xml-13.jpg)

Screen about using diagnostic data for **tailored experiences** (tips, ads, recommendations); **No** is selected.

**Relevant XML**

```xml
<OOBE>
  <ProtectYourPC>1</ProtectYourPC>
</OOBE>
```

- Also governed by the same privacy level.  
- The unattended template enforces the non‑personalized option without showing this screen.

---

## Screenshot `unattend.xml-14.jpg` – (reserved)

`unattend.xml-14.jpg` can be used for any additional OOBE or system screen you want to document. Map it to the appropriate XML section following the same pattern as above.

---

## Screenshot `unattend.xml-15.jpg` – (reserved)

`unattend.xml-15.jpg` is reserved for future extension (for example, activation status after Sysprep or the first desktop after OOBE). Describe the screen and reference the relevant XML settings here if you decide to use it.

---

## How to read this mapping

- **Screenshots 01–02** – language and keyboard (`International-Core`).
- **Screenshot 03** – EULA, hidden via `HideEULAPage`.
- **Screenshots 04–08** – device name and user creation; only some are automated, most are skipped by `SkipUserOOBE`.
- **Screenshots 09–13** – privacy and diagnostics; governed mainly by `ProtectYourPC` and OOBE skip flags.
- **14–15** – placeholders for any extra documentation you add later.

Together with `Win11-SysprepCleanup.ps1`, this mapping shows exactly which manual OOBE steps are automated by `unattend.xml` and which ones remain manual or are handled by later cloud-init automation.
