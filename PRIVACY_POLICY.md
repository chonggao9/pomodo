# PomoDo Privacy Policy

**Last Updated: September 11, 2026**  
**Effective Date: September 11, 2026**

---

## 1. Introduction & Overview

Welcome to **PomoDo** ("we", "our", or "the App"). We are committed to protecting and respecting your personal privacy. PomoDo is designed under a **Local-First, Privacy-by-Default** philosophy. 

This Privacy Policy explains how our application handles information, how we protect your data, and your rights regarding the data stored within the App.

> **Key Takeaway**: PomoDo does **NOT** collect, upload, sell, or share your personal data, tasks, notes, or focus sessions. All your information is stored exclusively on your local device within an embedded SQLite database.

---

## 2. Information Collection and Use

### 2.1 Personal Data
PomoDo **does not require registration, login, or any personal account**. We do not collect:
- Your name, email address, phone number, or physical address.
- Your device identifiers, IMEI, MAC address, or advertising IDs (GAID/IDFA).
- Your location data or IP address.

### 2.2 User Content & App Data
All user-created data—including:
- To-Do tasks, subtasks, notes, priorities, and categories;
- Pomodoro focus duration, timestamps, and completion history;
- Custom settings, theme preferences, and sound volume choices;
is saved **strictly inside your device's private app storage** in a local SQLite database (`pomodo.db`). We have no access to this database.

### 2.3 Audio & White Noise
The built-in ambient sounds (such as rainfall, ocean waves, and campfire) are bundled as local offline assets within the application package. Playing audio does not transmit any network packets or track your listening habits.

---

## 3. Data Sharing, Transfer, and Third Parties

- **No Third-Party Analytics**: PomoDo does not integrate third-party tracking, advertising, or profiling SDKs (e.g., no Google AdMob, Facebook SDK, Firebase Analytics, or AppsFlyer).
- **No Remote Servers**: PomoDo does not operate any centralized cloud servers to harvest user data.
- **No Third-Party Sharing**: Because we do not collect your data, we never sell, rent, disclose, or transfer any information to third parties.

---

## 4. Device Permissions

PomoDo requests only the bare minimum permissions necessary to function:
- **Vibration (`android.permission.VIBRATE`)**: Used solely to provide subtle haptic feedback when completing tasks or when a Pomodoro timer expires.
- **Wake Lock (`android.permission.WAKE_LOCK`)**: Used temporarily to keep the screen awake if you choose to keep the dial active during a focus session.
- **Foreground Service / Notifications**: Used strictly to notify you when a countdown timer finishes.

PomoDo **does not request** access to contacts, photos, microphone, camera, location, or SMS.

---

## 5. Data Storage, Security, and Backup

- **Local Storage Security**: Your database is stored within the Android sandboxed internal storage (`/data/data/com.pomodo.app.pomodo/`), protected by the operating system's sandbox isolation mechanism.
- **Data Portability & Export**: You have full control over your data. In **Settings -> Database Management**, you can export your complete SQLite database file at any time to your own local storage or cloud drive of your choice.

---

## 6. Data Retention and Deletion

- **Instant Deletion**: You can delete individual tasks, categories, or Pomodoro sessions directly in the App at any time.
- **Full Factory Reset**: You can clear all records and reset the database via **Settings -> Database Management -> Reset Database**.
- **App Uninstallation**: Uninstalling PomoDo from your device immediately and permanently deletes the local SQLite database and all associated cached files.

---

## 7. Children's Privacy (COPPA & GDPR-K Compliance)

PomoDo is a general-audience productivity application. It does not target children under the age of 13 (or 16 in the European Union), nor does it knowingly collect any personally identifiable information from children.

---

## 8. Changes to This Privacy Policy

We may update our Privacy Policy from time to time. Any changes will be posted on this page with an updated "Last Updated" date. We encourage you to review this page periodically.

---

## 9. Contact Us

If you have any questions, concerns, or feedback regarding this Privacy Policy or our practices, please reach out to us at:

- **Email**: support@pomodo.app (or your developer email)
- **GitHub Issues**: [https://github.com/chonggao9/pomodo/issues](https://github.com/chonggao9/pomodo/issues)
