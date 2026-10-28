/// Built-in sticker catalogue for the sticker panel.
///
/// Each category is a space-separated row of emoji so the data stays compact.
library;

/// Sticker categories, in tab order. Labels live in `StickerCategoryLabel`.
enum StickerCategory {
  emoji,
  animals,
  food,
  travel,
  objects,
  symbols,
  hands,
  nature,
}

const _stickerRows = <StickerCategory, String>{
  StickerCategory.emoji:
      '😀 😃 😄 😁 😂 🤣 😊 😇 🥰 😍 🤩 😘 😋 😜 🤪 😎 🤔 🤨 😏 😌 🥳 🤗 🫡 🫠',
  StickerCategory.animals:
      '🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐸 🐵 🐔 🦄 🐝 🦋 🐢 🐙 🦀 🐬 🦅',
  StickerCategory.food:
      '🍎 🍊 🍋 🍇 🍓 🍑 🍕 🍔 🌮 🌯 🍣 🍱 🍩 🍪 🎂 🍰 🍦 🍫 ☕ 🧁 🥐 🥗 🍿 🧃',
  StickerCategory.travel:
      '✈️ 🚗 🚀 ⛵ 🏖️ 🗽 🏔️ 🌍 🏰 🎡 ⛺ 🏝️ 🗼 🌋 🏕️ 🚂 🚁 ⛷️ 🏄 🎢 🚢 🛸 🌅 🗺️',
  StickerCategory.objects:
      '📱 💻 📷 🎮 🎧 📚 ✏️ 🔑 💡 ⌚ 🎁 🎈 🔔 📌 🎯 🏆 🎪 🎭 🎬 🎤 🎸 🎹 🔬 🔭',
  StickerCategory.symbols:
      '❤️ 🧡 💛 💚 💙 💜 🤎 🖤 ⭐ ✨ 💫 🔥 💯 ✅ ❌ ⚡ 💪 👍 🎉 🎊 ♻️ 💎 🏳️‍🌈 ☮️',
  StickerCategory.hands:
      '👋 🤚 ✋ 🖖 👌 🤌 🤏 ✌️ 🤞 🫰 🤟 🤙 👈 👉 👆 👇 ☝️ 👍 👎 👏 🙌 🫶 🤝 🙏',
  StickerCategory.nature:
      '🌸 🌺 🌻 🌹 🌷 🪻 💐 🌿 🍀 🍁 🍂 🌴 🌵 🌊 ☀️ 🌙 ⭐ 🌈 ☁️ ❄️ 💧 🌪️ 🔥 🍃',
};

final _stickers = <StickerCategory, List<String>>{
  for (final e in _stickerRows.entries)
    e.key: List.unmodifiable(e.value.split(' ')),
};

/// Stickers of [category].
List<String> stickersForCategory(StickerCategory category) =>
    _stickers[category]!;

/// The sticker at [index] in [category], or `null` when [index] is out of
/// range (for example no sticker selected yet, i.e. `-1`).
String? stickerAt(StickerCategory category, int index) {
  final stickers = stickersForCategory(category);
  if (index < 0 || index >= stickers.length) return null;
  return stickers[index];
}
