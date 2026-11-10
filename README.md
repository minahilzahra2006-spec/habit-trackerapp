# 📱 Flutter Habit Tracker App

A feature-rich, production-ready Habit Tracker application built with Flutter, powered by local Hive database persistence, dynamic Provider state management, and interactive charts.

## ✨ Features & Functionality

* **Habit Management & Validation:** Create custom habits with names, descriptions, and a 30-character limit constraint.
* **Repeating Days Scheduling:** Select custom weekly active days (Monday to Sunday) using interactive selection chips.
* **Today Screen & Live Progress:** Filter habits scheduled specifically for today, complete/undo tasks with single-tap checkboxes, and monitor a real-time progress bar (`X of Y done`).
* **Monthly Calendar Heatmap:** Tap any habit to open a detailed monthly view highlighting completed days and tracking the monthly completion rate (%).
* **Streaks & Gamification:** Automatically calculate and persist continuous daily streaks (🔥) alongside all-time best streak records (🏆).
* **Statistics & Analytics:** Visualize last 7 days check-ins using dynamic bar charts (`fl_chart`) and track your top-performing habit of the month.
* **Dark / Light Theme Toggle:** Seamless theme switching supported by persistent local preferences.
* **Data Management:** Secure confirmation workflows for clearing or resetting all stored application data.


## 🛠️ Tech Stack & Packages

* **Framework:** Flutter (Cross-platform / Web compatible)
* **State Management:** Provider (`^6.1.1`)
* **Local Database:** Hive & Hive Flutter (`^2.2.3` / `^1.1.0`)
* **Charts & Analytics:** FL Chart (`^0.68.0`)
