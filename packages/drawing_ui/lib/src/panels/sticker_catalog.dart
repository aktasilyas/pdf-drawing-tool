/// Built-in sticker catalogue for the sticker panel.
///
/// Each category is a space-separated row of emoji so the data stays compact.
library;

/// Sticker categories, in tab order.
const stickerCategories = [
  'Emoji',
  'Hayvanlar',
  'Yiyecek',
  'Seyahat',
  'Nesneler',
  'Semboller',
  'Eller',
  'Doğa',
];

const _stickerRows = <String, String>{
  'Emoji':
      '😀 😃 😄 😁 😂 🤣 😊 😇 🥰 😍 🤩 😘 😋 😜 🤪 😎 🤔 🤨 😏 😌 🥳 🤗 🫡 🫠',
  'Hayvanlar':
      '🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐸 🐵 🐔 🦄 🐝 🦋 🐢 🐙 🦀 🐬 🦅',
  'Yiyecek':
      '🍎 🍊 🍋 🍇 🍓 🍑 🍕 🍔 🌮 🌯 🍣 🍱 🍩 🍪 🎂 🍰 🍦 🍫 ☕ 🧁 🥐 🥗 🍿 🧃',
  'Seyahat':
      '✈️ 🚗 🚀 ⛵ 🏖️ 🗽 🏔️ 🌍 🏰 🎡 ⛺ 🏝️ 🗼 🌋 🏕️ 🚂 🚁 ⛷️ 🏄 🎢 🚢 🛸 🌅 🗺️',
  'Nesneler':
      '📱 💻 📷 🎮 🎧 📚 ✏️ 🔑 💡 ⌚ 🎁 🎈 🔔 📌 🎯 🏆 🎪 🎭 🎬 🎤 🎸 🎹 🔬 🔭',
  'Semboller':
      '❤️ 🧡 💛 💚 💙 💜 🤎 🖤 ⭐ ✨ 💫 🔥 💯 ✅ ❌ ⚡ 💪 👍 🎉 🎊 ♻️ 💎 🏳️‍🌈 ☮️',
  'Eller':
      '👋 🤚 ✋ 🖖 👌 🤌 🤏 ✌️ 🤞 🫰 🤟 🤙 👈 👉 👆 👇 ☝️ 👍 👎 👏 🙌 🫶 🤝 🙏',
  'Doğa':
      '🌸 🌺 🌻 🌹 🌷 🪻 💐 🌿 🍀 🍁 🍂 🌴 🌵 🌊 ☀️ 🌙 ⭐ 🌈 ☁️ ❄️ 💧 🌪️ 🔥 🍃',
};

final _stickers = <String, List<String>>{
  for (final e in _stickerRows.entries)
    e.key: List.unmodifiable(e.value.split(' ')),
};

/// Stickers of [category], or a single placeholder for an unknown category.
List<String> stickersForCategory(String category) =>
    _stickers[category] ?? const ['❓'];

/// The sticker at [index] in [category], or `null` when [index] is out of
/// range (for example no sticker selected yet, i.e. `-1`).
String? stickerAt(String category, int index) {
  final stickers = stickersForCategory(category);
  if (index < 0 || index >= stickers.length) return null;
  return stickers[index];
}
