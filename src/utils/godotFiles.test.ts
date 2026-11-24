import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {
  buildFileTree,
  filterGodotFiles,
  formatByteSize,
  normalizeGodotFiles,
  tokenizeLine,
} from './godotFiles';

const SAMPLE_MODULES: Record<string, string> = {
  '/godot_project/scripts/GameManager.gd': 'extends Node\n@export var level: int = 1\n# comment\n',
  '/godot_project/scenes/Main.tscn': '[gd_scene load_steps=2 format=3]\n[node name="Main" type="Control"]\n',
  '/godot_project/resources/items/wooden_sword.tres': '[gd_resource type="Resource" format=3]\nbonus_strength = 3\n',
  '/godot_project/CLAUDE.md': '# Architecture\nUse `GameManager`.\n',
  '/godot_project/project.godot': 'config_version=5\nconfig/name="Hero Tale"\n',
};

const GODOT_ROOT = path.resolve(process.cwd(), 'godot_project');

function resolveResPath(resPath: string): string {
  assert.ok(resPath.startsWith('res://'), `Expected res:// path, got ${resPath}`);
  return path.join(GODOT_ROOT, resPath.slice('res://'.length));
}

function collectFilesRecursive(dir: string, ext: string): string[] {
  const results: string[] = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...collectFilesRecursive(fullPath, ext));
    } else if (entry.name.endsWith(ext)) {
      results.push(fullPath);
    }
  }
  return results;
}

function parseSkillTres(filePath: string): {
  id: string;
  gridPos: string;
  prerequisites: string[];
} {
  const content = fs.readFileSync(filePath, 'utf-8');
  const idMatch = /^id\s*=\s*"([^"]+)"/m.exec(content);
  const posMatch = /^grid_position\s*=\s*(Vector2\([^)]+\))/m.exec(content);
  const prereqMatch = /^prerequisites\s*=\s*Array\[String\]\(\[([^\]]*)\]\)/m.exec(content);

  assert.ok(idMatch, `Missing id in ${filePath}`);
  assert.ok(posMatch, `Missing grid_position in ${filePath}`);

  const prerequisites: string[] = [];
  if (prereqMatch && prereqMatch[1].trim().length > 0) {
    for (const m of prereqMatch[1].matchAll(/"([^"]+)"/g)) {
      prerequisites.push(m[1]);
    }
  }

  return {
    id: idMatch[1],
    gridPos: posMatch[1].replace(/\s+/g, ''),
    prerequisites,
  };
}

test('normalizeGodotFiles strips prefix and detects metadata', () => {
  const files = normalizeGodotFiles(SAMPLE_MODULES);
  assert.equal(files.length, 5);
  assert.equal(files[0].path, 'CLAUDE.md');
  assert.equal(files[1].path, 'project.godot');

  const gm = files.find((f) => f.path === 'scripts/GameManager.gd');
  assert.ok(gm);
  assert.equal(gm.language, 'gdscript');
  assert.equal(gm.extension, 'gd');
  assert.equal(gm.lineCount, 4);
});

test('buildFileTree sorts folders before root files and preserves hierarchy', () => {
  const files = normalizeGodotFiles(SAMPLE_MODULES);
  const tree = buildFileTree(files);

  assert.equal(tree[0].type, 'folder');
  assert.equal(tree[0].name, 'resources');
  assert.equal(tree[1].type, 'folder');
  assert.equal(tree[1].name, 'scenes');
  assert.equal(tree[2].type, 'folder');
  assert.equal(tree[2].name, 'scripts');

  const rootFiles = tree.filter((n) => n.type === 'file').map((n) => n.name);
  assert.deepEqual(rootFiles, ['CLAUDE.md', 'project.godot']);
});

test('filterGodotFiles filters by extension and search query', () => {
  const files = normalizeGodotFiles(SAMPLE_MODULES);
  assert.equal(filterGodotFiles(files, '', 'gd').length, 1);
  assert.equal(filterGodotFiles(files, '', 'tres').length, 1);
  assert.equal(filterGodotFiles(files, 'sword', 'all').length, 1);
  assert.equal(filterGodotFiles(files, 'nonexistent', 'all').length, 0);
});

test('tokenizeLine highlights GDScript, resources, and markdown accurately', () => {
  const gdTokens = tokenizeLine('@export var hp: float = 100.0 # init', 'gdscript');
  assert.ok(gdTokens.some((t) => t.text === '@export' && t.kind === 'annotation'));
  assert.ok(gdTokens.some((t) => t.text === 'var' && t.kind === 'keyword'));
  assert.ok(gdTokens.some((t) => t.text === 'float' && t.kind === 'type'));
  assert.ok(gdTokens.some((t) => t.text === '100.0' && t.kind === 'number'));
  assert.ok(gdTokens.some((t) => t.text === '# init' && t.kind === 'comment'));

  const tresTokens = tokenizeLine('bonus_strength = 3', 'godot-resource');
  assert.equal(tresTokens[0].kind, 'property');
  assert.ok(tresTokens.some((t) => t.text === '3' && t.kind === 'number'));

  const mdTokens = tokenizeLine('# Title', 'markdown');
  assert.equal(mdTokens[0].kind, 'heading');
});

test('formatByteSize formats bytes and kilobytes cleanly', () => {
  assert.equal(formatByteSize(512), '512 Б');
  assert.equal(formatByteSize(2048), '2.0 КБ');
});

test('tokenizeLine highlights HeroClassData, DarkSkillNodeData, PetData, and NumberFormatter types', () => {
  const tokens = tokenizeLine('var x: DarkSkillNodeData = NumberFormatter.format_number(1e24); var c: HeroClassData; var p: PetData', 'gdscript');
  assert.ok(tokens.some((t) => t.text === 'DarkSkillNodeData' && t.kind === 'type'));
  assert.ok(tokens.some((t) => t.text === 'HeroClassData' && t.kind === 'type'));
  assert.ok(tokens.some((t) => t.text === 'PetData' && t.kind === 'type'));
  assert.ok(tokens.some((t) => t.text === 'NumberFormatter' && t.kind === 'type'));
});

test('all res:// paths in GameManager.gd, .tscn, and .tres files resolve on disk', () => {
  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  const gmPaths = [...gmContent.matchAll(/"(res:\/\/[^"]+)"/g)]
    .map((m) => m[1])
    .filter((p) => !p.includes('%'));
  assert.ok(gmPaths.length >= 60, 'Expected GameManager.gd to register locations, items, skills, classes');
  for (const resPath of gmPaths) {
    assert.ok(fs.existsSync(resolveResPath(resPath)), `Missing GameManager resource on disk: ${resPath}`);
  }

  const allSceneAndRes = [
    ...collectFilesRecursive(path.join(GODOT_ROOT, 'scenes'), '.tscn'),
    ...collectFilesRecursive(path.join(GODOT_ROOT, 'resources'), '.tres'),
  ];
  for (const filePath of allSceneAndRes) {
    const content = fs.readFileSync(filePath, 'utf-8');
    for (const match of content.matchAll(/path="(res:\/\/[^"]+)"/g)) {
      const target = resolveResPath(match[1]);
      assert.ok(fs.existsSync(target), `Broken ext_resource ${match[1]} in ${filePath}`);
    }
  }
});

test('skill tree and dark skill tree have zero overlapping nodes, valid prereqs, and wind_step is reachable', () => {
  const skillFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/skills'), '.tres');
  assert.equal(skillFiles.length, 44, 'Expected expanded 44-node regular skill tree');
  const skills = skillFiles.map(parseSkillTres);

  const skillPosSet = new Set<string>();
  const skillMap = new Map<string, ReturnType<typeof parseSkillTres>>();
  for (const s of skills) {
    assert.ok(!skillPosSet.has(s.gridPos), `Duplicate grid_position ${s.gridPos} in regular skill tree (${s.id})`);
    skillPosSet.add(s.gridPos);
    assert.ok(!skillMap.has(s.id), `Duplicate skill id: ${s.id}`);
    skillMap.set(s.id, s);
  }

  const reachableSkills = new Set<string>(['hero_foundation']);
  let changed = true;
  while (changed) {
    changed = false;
    for (const s of skills) {
      if (!reachableSkills.has(s.id) && s.prerequisites.every((p) => skillMap.has(p) && reachableSkills.has(p))) {
        reachableSkills.add(s.id);
        changed = true;
      }
    }
  }
  assert.equal(reachableSkills.size, skills.length, 'Every regular skill must be reachable from hero_foundation');
  assert.ok(reachableSkills.has('wind_step'), 'wind_step must be reachable and non-overlapping');

  const darkFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/dark_skills'), '.tres');
  assert.equal(darkFiles.length, 31, 'Expected expanded 31-node dark skill tree');
  const darkSkills = darkFiles.map(parseSkillTres);

  const darkPosSet = new Set<string>();
  const darkMap = new Map<string, ReturnType<typeof parseSkillTres>>();
  for (const d of darkSkills) {
    assert.ok(!darkPosSet.has(d.gridPos), `Duplicate grid_position ${d.gridPos} in dark skill tree (${d.id})`);
    darkPosSet.add(d.gridPos);
    assert.ok(!darkMap.has(d.id), `Duplicate dark skill id: ${d.id}`);
    darkMap.set(d.id, d);
  }

  const reachableDark = new Set<string>(['abyss_awakening']);
  changed = true;
  while (changed) {
    changed = false;
    for (const d of darkSkills) {
      if (!reachableDark.has(d.id) && d.prerequisites.every((p) => darkMap.has(p) && reachableDark.has(p))) {
        reachableDark.add(d.id);
        changed = true;
      }
    }
  }
  assert.equal(reachableDark.size, darkSkills.length, 'Every dark skill must be reachable from abyss_awakening');
});

test('resource .tres properties match GDScript definitions and no integer divisions or stale HeroClassData fields remain', () => {
  const resourceMap: Array<[string, string]> = [
    ['scripts/resources/HeroClassData.gd', 'resources/classes'],
    ['scripts/resources/ItemData.gd', 'resources/items'],
    ['scripts/resources/EnemyData.gd', 'resources/enemies'],
    ['scripts/resources/LocationData.gd', 'resources/locations'],
    ['scripts/resources/SkillNodeData.gd', 'resources/skills'],
    ['scripts/resources/DarkSkillNodeData.gd', 'resources/dark_skills'],
    ['scripts/resources/AbilityData.gd', 'resources/abilities'],
    ['scripts/resources/PetData.gd', 'resources/pets'],
    ['scripts/resources/CropData.gd', 'resources/crops'],
  ];

  for (const [gdRel, dirRel] of resourceMap) {
    const gdContent = fs.readFileSync(path.join(GODOT_ROOT, gdRel), 'utf-8');
    const declaredVars = new Set<string>();
    for (const m of gdContent.matchAll(/^(?:@export[^\n]*\s+)?var\s+([a-zA-Z0-9_]+)/gm)) {
      declaredVars.add(m[1]);
    }
    const dirAbs = path.join(GODOT_ROOT, dirRel);
    for (const entry of fs.readdirSync(dirAbs)) {
      if (!entry.endsWith('.tres')) continue;
      const tresContent = fs.readFileSync(path.join(dirAbs, entry), 'utf-8');
      const resourceSection = tresContent.split('[resource]')[1] ?? '';
      for (const line of resourceSection.split(/\r?\n/)) {
        const m = /^([a-zA-Z0-9_]+)\s*=/.exec(line);
        if (m && m[1] !== 'script' && m[1] !== 'metadata') {
          assert.ok(declaredVars.has(m[1]), `Unknown property "${m[1]}" in ${dirRel}/${entry} (not declared in ${gdRel})`);
        }
      }
    }
  }

  const classUi = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/ClassUI.gd'), 'utf-8');
  assert.ok(!classUi.includes('role_tagline'), 'ClassUI.gd must not access stale property role_tagline');
  assert.ok(classUi.includes('hc.subtitle'), 'ClassUI.gd must use hc.subtitle');

  const allGd = collectFilesRecursive(path.join(GODOT_ROOT, 'scripts'), '.gd');
  const forbiddenIntDiv = /\b(total_sec|target_diff|difficulty_level|_selected_difficulty|kills_in_run|shop_pack_amount|% 3600\))\s*\/\s*\d+\b/;
  for (const gdFile of allGd) {
    const content = fs.readFileSync(gdFile, 'utf-8');
    assert.ok(!forbiddenIntDiv.test(content), `Found unguarded integer division in ${gdFile}`);
  }
});

test('spellbook has exactly 27 abilities (19 general + 7 blood_archmage + 1 reflector exclusives), max 3 active slots, buffs, and overcharge_burn', () => {
  const abilityFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/abilities'), '.tres');
  assert.equal(abilityFiles.length, 27, 'Expected exactly 27 abilities');

  let bloodExclusiveCount = 0;
  let reflectorExclusiveCount = 0;
  let buffCount = 0;
  let hasOverchargeBurn = false;
  const ids = new Set<string>();

  for (const filePath of abilityFiles) {
    const txt = fs.readFileSync(filePath, 'utf-8');
    const idMatch = /^id\s*=\s*"([^"]+)"/m.exec(txt);
    assert.ok(idMatch, `Missing id in ${filePath}`);
    assert.ok(!ids.has(idMatch[1]), `Duplicate ability id: ${idMatch[1]}`);
    ids.add(idMatch[1]);

    if (/^required_class_id\s*=\s*"blood_archmage"/m.test(txt)) {
      bloodExclusiveCount++;
    }
    if (/^required_class_id\s*=\s*"reflector"/m.test(txt)) {
      reflectorExclusiveCount++;
    }
    if (/^effect_type\s*=\s*"buff"/m.test(txt)) {
      buffCount++;
    }
    if (/^effect_type\s*=\s*"overcharge_burn"/m.test(txt)) {
      hasOverchargeBurn = true;
    }
  }

  assert.equal(bloodExclusiveCount, 7, 'Expected exactly 7 Blood Archmage exclusive abilities');
  assert.equal(reflectorExclusiveCount, 1, 'Expected exactly 1 Reflector exclusive ability');
  assert.ok(buffCount >= 4, 'Expected multiple buff abilities');
  assert.ok(hasOverchargeBurn, 'Expected escalating overcharge_burn burst spell');

  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  assert.ok(gmContent.includes('MAX_ACTIVE_ABILITY_SLOTS: int = 3'), 'GameManager must enforce max 3 active spell slots');
});

test('Reflector class and 6 immortal Pets (including Firework 5s start-of-battle stun) are wired cleanly', () => {
  const classFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/classes'), '.tres');
  assert.equal(classFiles.length, 7, 'Expected 7 hero classes including reflector');
  const reflectorPath = path.join(GODOT_ROOT, 'resources/classes/reflector.tres');
  assert.ok(fs.existsSync(reflectorPath), 'reflector.tres must exist');
  const reflectorContent = fs.readFileSync(reflectorPath, 'utf-8');
  assert.ok(/id\s*=\s*"reflector"/.test(reflectorContent));
  assert.ok(/required_difficulty\s*=\s*50/.test(reflectorContent));

  const petFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/pets'), '.tres');
  assert.equal(petFiles.length, 6, 'Expected 6 pet companions');
  const fireworkPath = path.join(GODOT_ROOT, 'resources/pets/firework_spark.tres');
  assert.ok(fs.existsSync(fireworkPath), 'firework_spark.tres must exist');
  const fireworkContent = fs.readFileSync(fireworkPath, 'utf-8');
  assert.ok(/effect_type\s*=\s*"start_stun"/.test(fireworkContent));
  assert.ok(/effect_value\s*=\s*5\.0/.test(fireworkContent));

  const saveContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/SaveData.gd'), 'utf-8');
  assert.ok(saveContent.includes('owned_pet_ids'), 'SaveData must persist owned_pet_ids');
  assert.ok(saveContent.includes('equipped_pet_id'), 'SaveData must persist equipped_pet_id');

  const gmReflContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  assert.ok(gmReflContent.includes('base_reflect: float = 0.20'), 'GameManager must define 20% base reflection for Reflector');
  assert.ok(gmReflContent.includes('func get_reflector_mitigation_pct()'), 'GameManager must expose pre-armor mitigation cap (up to 99%)');

  const combatContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  assert.ok(combatContent.includes('raw_damage * total_reflect_pct'), 'CombatSystem must reflect total_reflect_pct of raw incoming damage for Reflector');
  assert.ok(combatContent.includes('get_reflector_mitigation_pct()'), 'CombatSystem must disperse incoming damage before armor using get_reflector_mitigation_pct()');
  assert.ok(combatContent.includes('get_max_hp() * 0.05'), 'CombatSystem must pulse 5% Max HP/s for Reflector');
  assert.ok(combatContent.includes('enemy_max_hp * 0.001'), 'CombatSystem must apply 0.1% enemy Max HP/s rot for Reflector');
  assert.ok(combatContent.includes('start_stun'), 'CombatSystem must trigger start_stun pet effect on enemy spawn');
});

test('all 44 regular skills cost 1 SP with empowered bonuses, XP curve is steepened, and Dark Points are capped at 1 claim per difficulty', () => {
  const skillFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/skills'), '.tres');
  assert.equal(skillFiles.length, 44);

  for (const filePath of skillFiles) {
    const txt = fs.readFileSync(filePath, 'utf-8');
    assert.ok(/^cost_skill_points\s*=\s*1$/m.test(txt), `Skill ${path.basename(filePath)} must cost exactly 1 SP`);
  }

  const checkBonusAtLeast = (file: string, minVal: number) => {
    const txt = fs.readFileSync(path.join(GODOT_ROOT, 'resources/skills', file), 'utf-8');
    const m = /^bonus_value\s*=\s*([0-9.]+)/m.exec(txt);
    assert.ok(m, `Missing bonus_value in ${file}`);
    assert.ok(parseFloat(m[1]) >= minVal, `Expected ${file} bonus_value >= ${minVal}, got ${m[1]}`);
  };
  checkBonusAtLeast('colossus_wrath.tres', 60);
  checkBonusAtLeast('immortal_vessel.tres', 60);
  checkBonusAtLeast('midas_blessing.tres', 1.8);
  checkBonusAtLeast('cosmic_enlightenment.tres', 1.8);
  checkBonusAtLeast('elemental_mastery.tres', 1.0);
  checkBonusAtLeast('wind_archer_mastery.tres', 1.0);
  checkBonusAtLeast('guardian_aegis.tres', 80);

  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  assert.ok(gmContent.includes('150.0 * pow(1.10'), 'GameManager must use steeper exponential+quadratic XP curve');
  assert.ok(gmContent.includes('dark_points_claimed_difficulties'), 'GameManager must track claimed Dark Points per difficulty');
  assert.ok(gmContent.includes('if not dark_points_claimed_difficulties.has(difficulty_level):'), 'GameManager must award Dark Points at most once per difficulty');

  const saveContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/SaveData.gd'), 'utf-8');
  assert.ok(saveContent.includes('dark_points_claimed_difficulties'), 'SaveData must persist dark_points_claimed_difficulties');
});

test('mana potions, buff potions, village map hotspots, Diff-10 Sanctuary garden/brewing, scarlet petal (2000 boss kills), and deterministic Alchemist safety flag are implemented', () => {
  const itemFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/items'), '.tres');
  assert.equal(itemFiles.length, 100, 'Expected 100 item resources (including mage gear, offhand shields/talismans, mine materials, eternal dark-forged gear + 6 ultimates, 6 Dark Shop consumables, and abyss_difficulty_reset_orb)');

  const cropFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/crops'), '.tres');
  assert.equal(cropFiles.length, 10, 'Expected 10 Sanctuary crop resources (4 light + 6 dark)');

  const moonMintTxt = fs.readFileSync(path.join(GODOT_ROOT, 'resources/crops/moon_mint.tres'), 'utf-8');
  assert.ok(/base_drop_chance\s*=\s*0\.0005/.test(moonMintTxt), 'moon_mint must drop with 0.05% (0.0005) base chance');

  const scarletTxt = fs.readFileSync(path.join(GODOT_ROOT, 'resources/crops/scarlet_petal.tres'), 'utf-8');
  assert.ok(/required_final_boss_kills\s*=\s*2000/.test(scarletTxt), 'scarlet_petal must require 2000 final boss kills');

  assert.ok(fs.existsSync(path.join(GODOT_ROOT, 'assets/textures/village_map.jpg')), 'village_map.jpg texture must exist');
  const villageScene = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/VillageMapUI.tscn'), 'utf-8');
  for (const hotspot of ['HouseHotspot', 'ShopBuildingHotspot', 'DogHotspot', 'MountainsHotspot', 'GoShopButton', 'GoEnchantButton']) {
    assert.ok(villageScene.includes(hotspot), `VillageMapUI.tscn must define ${hotspot}`);
  }

  const invScene = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/InventoryUI.tscn'), 'utf-8');
  assert.ok(invScene.includes('QuickManaPotionButton'), 'InventoryUI.tscn must include QuickManaPotionButton');

  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  assert.ok(gmContent.includes('ALCHEMY_UNLOCK_DIFFICULTY: int = 10'), 'Sanctuary & brewing must unlock at Difficulty 10');
  assert.ok(gmContent.includes('alchemist_next_mistake_safe: bool'), 'Alchemist explosion safety must use deterministic boolean flag');
  assert.ok(gmContent.includes('on_final_boss_killed_for_garden'), 'GameManager must track final boss kills for Scarlet Petal');
  assert.ok(gmContent.includes('preserved_garden_items'), 'Seeds, harvests, garden plots, and brewing cauldrons must persist across start_new_run()');

  const combatContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  assert.ok(combatContent.includes('on_final_boss_killed_for_garden'), 'CombatSystem must increment Scarlet Petal boss kill counter on FINAL_BOSS_ID defeat');
  assert.ok(combatContent.includes('roll_rare_seed_drops'), 'CombatSystem must roll rare seed drops on enemy defeat');

  for (const lockedSkill of ['herbal_mastery.tres', 'master_brewer.tres']) {
    const txt = fs.readFileSync(path.join(GODOT_ROOT, 'resources/skills', lockedSkill), 'utf-8');
    assert.ok(/requires_alchemy\s*=\s*true/.test(txt), `${lockedSkill} must be locked behind requires_alchemy = true`);
  }
  for (const lockedDark of ['abyss_botanist.tres', 'eternal_cauldron.tres']) {
    const txt = fs.readFileSync(path.join(GODOT_ROOT, 'resources/dark_skills', lockedDark), 'utf-8');
    assert.ok(/requires_alchemy\s*=\s*true/.test(txt), `${lockedDark} must be locked behind requires_alchemy = true`);
  }
});

test('SpellbookUI updates slot and spell buttons in-place without rebuilding on cooldown ticks', () => {
  const spellbookGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/SpellbookUI.gd'), 'utf-8');
  assert.ok(spellbookGd.includes('_update_active_slots()'), 'SpellbookUI must update active slots in-place');
  assert.ok(spellbookGd.includes('_update_spell_list()'), 'SpellbookUI must update spell list in-place');
  assert.ok(spellbookGd.includes('_compute_state_signature()'), 'SpellbookUI must skip redundant refreshes during cooldown ticks');
  assert.ok(spellbookGd.includes('is_visible_in_tree()'), 'SpellbookUI must defer refreshes when hidden');
});

test('Shop excludes high-tier melee/armor (drop-only) while keeping starter gear and all ranged weapons/ammo', () => {
  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  const shopMatch = /const SHOP_ITEM_PATHS: Array\[String\] = \[([\s\S]*?)\]/.exec(gmContent);
  assert.ok(shopMatch, 'Expected SHOP_ITEM_PATHS in GameManager.gd');
  const shopBlock = shopMatch[1];

  const dropOnlyItems = [
    'steel_halberd.tres',
    'assassin_kris.tres',
    'dragonbone_blade.tres',
    'trident_of_abyss.tres',
    'astral_greatsword.tres',
    'steel_plate.tres',
    'dragonscale_armor.tres',
    'abyssal_carapace.tres',
    'celestial_aegis.tres',
  ];
  for (const item of dropOnlyItems) {
    assert.ok(!shopBlock.includes(item), `High-tier item ${item} should not be sold in shop`);
  }

  const keptItems = [
    'wooden_sword.tres',
    'hunter_dagger.tres',
    'iron_sword.tres',
    'leather_jacket.tres',
    'chainmail_armor.tres',
    'wooden_bow.tres',
    'iron_crossbow.tres',
    'elven_longbow.tres',
    'dragon_crossbow.tres',
    'astral_bow.tres',
    'wooden_arrows.tres',
    'iron_bolts.tres',
    'steel_arrows.tres',
    'mithril_bolts.tres',
    'astral_arrows.tres',
    'abyss_bolts.tres',
  ];
  for (const item of keptItems) {
    assert.ok(shopBlock.includes(item), `Kept item ${item} must remain in shop`);
  }
});

test('Light Garden pet luring, withering duplicates, pet treat training, 0.03% Spirit Primordial seed with instant grow, and Spirit training are wired cleanly', () => {
  const lightCrops = ['light_clover.tres', 'honey_berry.tres', 'sky_chamomile.tres', 'spark_chili.tres'];
  for (const file of lightCrops) {
    const txt = fs.readFileSync(path.join(GODOT_ROOT, 'resources/crops', file), 'utf-8');
    assert.ok(/garden_type\s*=\s*"light"/.test(txt), `${file} must have garden_type = "light"`);
  }

  const primordialTxt = fs.readFileSync(path.join(GODOT_ROOT, 'resources/crops/spirit_primordial.tres'), 'utf-8');
  assert.ok(/final_boss_only\s*=\s*true/.test(primordialTxt), 'spirit_primordial must drop only from final boss');
  assert.ok(/boss_drop_chance\s*=\s*0\.0003/.test(primordialTxt), 'spirit_primordial must have 0.03% (0.0003) drop chance');
  assert.ok(/grow_seconds\s*=\s*3600\.0/.test(primordialTxt), 'spirit_primordial must grow slowly by default (3600s)');
  assert.ok(/is_spirit_training_crop\s*=\s*true/.test(primordialTxt), 'spirit_primordial must be flagged as spirit training crop');
  assert.ok(/instant_grow_feed_items\s*=/.test(primordialTxt), 'spirit_primordial must configure instant_grow_feed_items');

  const petFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/pets'), '.tres');
  const petIds: string[] = [];
  for (const pFile of petFiles) {
    const pTxt = fs.readFileSync(pFile, 'utf-8');
    const idMatch = /^id\s*=\s*"([^"]+)"/m.exec(pTxt);
    assert.ok(idMatch, `Missing id in ${pFile}`);
    petIds.push(idMatch[1]);
    assert.ok(/^favorite_treat_id\s*=\s*"[^"]+"/m.test(pTxt), `${pFile} must define favorite_treat_id`);
    assert.ok(/^secondary_treat_id\s*=\s*"[^"]+"/m.test(pTxt), `${pFile} must define secondary_treat_id`);
    assert.ok(/^lure_hint\s*=\s*"[^"]+"/m.test(pTxt), `${pFile} must define lure_hint`);
  }

  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  const recipeBlockMatch = /const PET_LURE_RECIPES: Array\[Dictionary\] = \[([\s\S]*?)\r?\n\]/.exec(gmContent);
  assert.ok(recipeBlockMatch, 'GameManager must define PET_LURE_RECIPES');
  const recipeBlock = recipeBlockMatch[1];
  const patternSet = new Set<string>();
  for (const pid of petIds) {
    assert.ok(recipeBlock.includes(`"pet_id": "${pid}"`), `PET_LURE_RECIPES must include ${pid}`);
  }
  for (const patMatch of recipeBlock.matchAll(/"pattern":\s*\[([^\]]+)\]/g)) {
    const norm = patMatch[1].replace(/\s+/g, '');
    assert.ok(!patternSet.has(norm), `Duplicate pet lure pattern in PET_LURE_RECIPES: ${norm}`);
    patternSet.add(norm);
  }
  assert.equal(patternSet.size, petIds.length, 'Every pet must have a unique 3-crop lure pattern');

  assert.ok(gmContent.includes('func lure_pet_from_light_garden()'), 'GameManager must implement lure_pet_from_light_garden');
  assert.ok(gmContent.includes('func train_pet_with_treat('), 'GameManager must implement train_pet_with_treat');
  assert.ok(gmContent.includes('func feed_growing_crop_for_instant_growth('), 'GameManager must implement feed_growing_crop_for_instant_growth');
  assert.ok(gmContent.includes('func train_spirit('), 'GameManager must implement train_spirit');
  assert.ok(gmContent.includes('func buy_pet(_pet_id: String)'), 'Gold buy_pet must be disabled in favor of Light Garden luring');

  const combatContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  assert.ok(combatContent.includes('get_spirit_power_multiplier'), 'CombatSystem must apply Spirit power multiplier');
  assert.ok(combatContent.includes('get_spirit_speed_multiplier'), 'CombatSystem must apply Spirit speed multiplier');
  assert.ok(combatContent.includes('get_pet_effect_value'), 'CombatSystem must use trained pet effect values');

  const sanctuaryGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/SanctuaryUI.gd'), 'utf-8');
  assert.ok(sanctuaryGd.includes('_last_light_sig'), 'SanctuaryUI must cache Light Garden signature');
  assert.ok(sanctuaryGd.includes('_last_dark_sig'), 'SanctuaryUI must cache Dark Garden signature');
  assert.ok(sanctuaryGd.includes('is_visible_in_tree()'), 'SanctuaryUI must skip rebuilds when hidden');

  const petUiGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/PetUI.gd'), 'utf-8');
  assert.ok(!petUiGd.includes('get_pet_buy_price') && !petUiGd.includes('buy_pet('), 'PetUI must not allow gold pet purchases');
  assert.ok(petUiGd.includes('train_pet_with_treat'), 'PetUI must support feeding treats directly to trained pets');
});

test('all GameManager.<member> references across GDScript files exist on GameManager.gd', () => {
  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  const gmMembers = new Set<string>();
  for (const m of gmContent.matchAll(/^(?:@export[^\n]*\s+)?(?:var|const|signal|enum)\s+([a-zA-Z0-9_]+)/gm)) {
    gmMembers.add(m[1]);
  }
  for (const m of gmContent.matchAll(/^func\s+([a-zA-Z0-9_]+)\s*\(/gm)) {
    gmMembers.add(m[1]);
  }

  const allGd = collectFilesRecursive(path.join(GODOT_ROOT, 'scripts'), '.gd');
  for (const gdFile of allGd) {
    const content = fs.readFileSync(gdFile, 'utf-8');
    const lines = content.split(/\r?\n/);
    for (let idx = 0; idx < lines.length; idx++) {
      const codePart = lines[idx].split('#')[0];
      for (const m of codePart.matchAll(/\bGameManager\.([a-zA-Z0-9_]+)/g)) {
        const member = m[1];
        assert.ok(
          gmMembers.has(member),
          `Invalid GameManager member "${member}" accessed at ${path.relative(GODOT_ROOT, gdFile)}:${idx + 1}`,
        );
      }
    }
  }
});

test('HoldAutoClicker provides 50/sec hold repeat across multi-tap UIs and no GDScript file has duplicate func declarations', () => {
  const autoClickerPath = path.join(GODOT_ROOT, 'scripts/utils/HoldAutoClicker.gd');
  assert.ok(fs.existsSync(autoClickerPath), 'HoldAutoClicker.gd must exist');
  const acContent = fs.readFileSync(autoClickerPath, 'utf-8');
  assert.ok(acContent.includes('DEFAULT_CLICKS_PER_SECOND: float = 50.0'), 'HoldAutoClicker must default to 50.0 clicks/sec');
  assert.ok(acContent.includes('static func attach('), 'HoldAutoClicker must expose attach() helper');

  const expectedWiredScripts = [
    'scripts/ui/StatsUI.gd',
    'scripts/ui/EnchantUI.gd',
    'scripts/ui/ShopUI.gd',
    'scripts/ui/InventoryUI.gd',
    'scripts/ui/RightSidebarUI.gd',
    'scripts/ui/PetUI.gd',
    'scripts/ui/SanctuaryUI.gd',
    'scripts/ui/DifficultyUI.gd',
    'scripts/ui/DarkForgeUI.gd',
    'scripts/ui/DarkShopUI.gd',
  ];
  for (const rel of expectedWiredScripts) {
    const content = fs.readFileSync(path.join(GODOT_ROOT, rel), 'utf-8');
    assert.ok(content.includes('HoldAutoClicker.attach('), `${rel} must attach HoldAutoClicker`);
    assert.ok(content.includes('50.0'), `${rel} must configure 50.0 clicks/sec`);
  }

  // Ensure AbilitySlotButton preserves its intentional 1.0s auto-cast hold instead of 50/sec repeat.
  const abilityBtn = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/AbilitySlotButton.gd'), 'utf-8');
  assert.ok(!abilityBtn.includes('HoldAutoClicker'), 'AbilitySlotButton must preserve 1.0s auto-cast hold behavior');

  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  assert.ok(gmContent.includes('func save_game(force_immediate: bool = false)'), 'GameManager.save_game must throttle rapid bursts safely');

  // Verify no GDScript file declares duplicate top-level functions.
  const allGd = collectFilesRecursive(path.join(GODOT_ROOT, 'scripts'), '.gd');
  for (const gdFile of allGd) {
    const content = fs.readFileSync(gdFile, 'utf-8');
    const seenFuncs = new Set<string>();
    for (const m of content.matchAll(/^(?:static\s+)?func\s+([a-zA-Z0-9_]+)\s*\(/gm)) {
      const fnName = m[1];
      assert.ok(!seenFuncs.has(fnName), `Duplicate function "${fnName}" in ${path.relative(GODOT_ROOT, gdFile)}`);
      seenFuncs.add(fnName);
    }
  }
});

test('soul_overload (overcharge_burn) fires at 12 ticks per second for up to 12 ticks', () => {
  const combatContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  assert.ok(
    combatContent.includes('OVERCHARGE_TICKS_PER_SECOND: float = 12.0'),
    'CombatSystem must define 12 ticks per second for overcharge_burn',
  );
  assert.ok(
    combatContent.includes('OVERCHARGE_TICK_INTERVAL: float = 1.0 / OVERCHARGE_TICKS_PER_SECOND'),
    'CombatSystem must compute tick interval as 1.0 / OVERCHARGE_TICKS_PER_SECOND',
  );
  assert.ok(
    combatContent.includes('OVERCHARGE_MAX_TICKS: int = 12'),
    'CombatSystem must cap overcharge_burn at 12 ticks (1 second max)',
  );

  const soulOverloadTres = fs.readFileSync(path.join(GODOT_ROOT, 'resources/abilities/soul_overload.tres'), 'utf-8');
  assert.ok(soulOverloadTres.includes('12 тиков/с'), 'soul_overload.tres description must mention 12 тиков/с');
  assert.ok(/^duration\s*=\s*1\.0$/m.test(soulOverloadTres), 'soul_overload.tres duration must be 1.0s');
});

test('Mage staffs & 2 tome types, Dark Forge (25%->20%->min 15% + eternal items), 1-attempt Mine, and configurable Auto-Potions are wired cleanly', () => {
  // 1. Mage equipment & drop-only top mage gear
  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  const shopMatch = /const SHOP_ITEM_PATHS: Array\[String\] = \[([\s\S]*?)\]/.exec(gmContent);
  assert.ok(shopMatch, 'Expected SHOP_ITEM_PATHS in GameManager.gd');
  const shopBlock = shopMatch[1];

  for (const dropOnlyMage of ['druid_staff.tres', 'lich_scepter.tres', 'astral_staff.tres', 'astral_vestments.tres']) {
    assert.ok(!shopBlock.includes(dropOnlyMage), `Top mage gear ${dropOnlyMage} should be drop-only`);
  }
  for (const starterMage of ['apprentice_staff.tres', 'crystal_wand.tres', 'mage_robe.tres', 'tome_intellect_flow.tres', 'tome_spell_amplify.tres']) {
    assert.ok(shopBlock.includes(starterMage), `Starter mage item ${starterMage} must remain in shop`);
  }

  const tomeType1 = fs.readFileSync(path.join(GODOT_ROOT, 'resources/items/tome_intellect_flow.tres'), 'utf-8');
  assert.ok(/bonus_intellect\s*=\s*\d+/.test(tomeType1) && /bonus_mana_cost_red\s*=\s*0\.\d+/.test(tomeType1), 'Type 1 tome must boost intellect and reduce mana cost');

  const tomeType2 = fs.readFileSync(path.join(GODOT_ROOT, 'resources/items/tome_spell_amplify.tres'), 'utf-8');
  assert.ok(/bonus_spell_power_pct\s*=\s*0\.\d+/.test(tomeType2) && /bonus_effect_duration_pct\s*=\s*0\.\d+/.test(tomeType2), 'Type 2 tome must boost spell power and effect duration');

  const eternalCodex = fs.readFileSync(path.join(GODOT_ROOT, 'resources/items/tome_eternal_codex.tres'), 'utf-8');
  assert.ok(/is_dark_forged\s*=\s*true/.test(eternalCodex), 'tome_eternal_codex must be eternal (is_dark_forged = true)');

  // 2. Dark Forge chances & UI wiring
  assert.ok(gmContent.includes('return 25.0') && gmContent.includes('maxf(15.0, 20.0'), 'Dark Forge enchant must use 25% -> 20% -> min 15% curve');
  assert.ok(gmContent.includes('item.is_dark_forged') && gmContent.includes('ItemData.ItemType.MATERIAL'), 'start_new_run() must preserve dark-forged items and mine materials');
  assert.ok(fs.existsSync(path.join(GODOT_ROOT, 'scenes/DarkForgeUI.tscn')), 'DarkForgeUI.tscn must exist');
  const heroMenuTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/HeroMenuUI.tscn'), 'utf-8');
  assert.ok(heroMenuTscn.includes('DarkForgeUI'), 'HeroMenuUI.tscn must embed DarkForgeUI');
  const villageTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/VillageMapUI.tscn'), 'utf-8');
  assert.ok(villageTscn.includes('GoDarkForgeButton'), 'VillageMapUI.tscn must link to Dark Forge');

  // 3. 1-Attempt Mine location, enemies, materials, lockout
  const mineLoc = fs.readFileSync(path.join(GODOT_ROOT, 'resources/locations/abandoned_mine.tres'), 'utf-8');
  assert.ok(/is_one_attempt_mine\s*=\s*true/.test(mineLoc), 'abandoned_mine.tres must set is_one_attempt_mine = true');
  const locFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/locations'), '.tres');
  assert.equal(locFiles.length, 12, 'Expected 12 locations including abandoned_mine');
  const enemyFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/enemies'), '.tres');
  assert.equal(enemyFiles.length, 26, 'Expected 26 enemies including 4 Mine enemies');
  assert.ok(fs.existsSync(path.join(GODOT_ROOT, 'resources/items/abyss_ore.tres')), 'abyss_ore.tres must exist');
  assert.ok(fs.existsSync(path.join(GODOT_ROOT, 'resources/items/ancient_page.tres')), 'ancient_page.tres must exist');

  const combatContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  assert.ok(combatContent.includes('fail_mine_run()'), 'CombatSystem must lock Mine on player death');
  assert.ok(combatContent.includes('roll_mine_ambient_find()'), 'CombatSystem must trigger ambient Mine finds');

  // 4. Configurable Auto-Potions (HP/MP thresholds + conditions + buff on-expire whitelist)
  const invScene = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/InventoryUI.tscn'), 'utf-8');
  for (const nodeName of ['AutoHpThresholdButton', 'AutoHpConditionButton', 'AutoManaToggle', 'AutoManaThresholdButton', 'AutoBuffToggle', 'AutoBuffConditionButton', 'BuffWhitelistFlow']) {
    assert.ok(invScene.includes(nodeName), `InventoryUI.tscn must include ${nodeName}`);
  }
  assert.ok(gmContent.includes('func try_auto_use_all_potions('), 'GameManager must implement try_auto_use_all_potions');
  assert.ok(combatContent.includes('try_auto_use_all_potions'), 'CombatSystem must invoke configurable auto-potions');
});

test('GameManager runs 8-minute autosave (480s) with atomic temp/backup saves and SaveData schema versioning', () => {
  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  const saveContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/SaveData.gd'), 'utf-8');

  assert.ok(gmContent.includes('const AUTOSAVE_INTERVAL: float = 480.0'), 'AUTOSAVE_INTERVAL must be 480.0 seconds (8 minutes)');
  assert.ok(gmContent.includes('const SAVE_BACKUP_PATH: String = "user://save.bak.tres"'), 'GameManager must maintain user://save.bak.tres backup');
  assert.ok(gmContent.includes('const SAVE_TEMP_PATH: String = "user://save.tmp.tres"'), 'GameManager must write atomically via user://save.tmp.tres');
  assert.ok(gmContent.includes('ResourceLoader.CACHE_MODE_IGNORE'), 'load_game must bypass stale resource cache');
  assert.ok(saveContent.includes('@export var save_version: int = 1'), 'SaveData must include save_version with safe default');
});

test('GameManager and StatsUI support .txt save export/import and clipboard transfer', () => {
  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  const statsTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/StatsUI.tscn'), 'utf-8');
  const statsGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/StatsUI.gd'), 'utf-8');

  for (const fnName of ['export_save_to_text', 'export_save_to_txt_file', 'import_save_from_text', 'import_save_from_txt_file']) {
    assert.ok(gmContent.includes(`func ${fnName}(`), `GameManager must define ${fnName}`);
  }
  assert.ok(gmContent.includes('HERO_TALE_SAVE_TXT'), 'Exported .txt save must include HERO_TALE_SAVE_TXT format marker');

  for (const nodeName of ['ExportTxtButton', 'ImportTxtButton', 'CopyTxtButton', 'PasteTxtButton', 'ExportTxtDialog', 'ImportTxtDialog']) {
    assert.ok(statsTscn.includes(nodeName), `StatsUI.tscn must include ${nodeName}`);
  }
  assert.ok(statsGd.includes('use_native_dialog = true'), 'StatsUI.gd must enable native file picker for Android/PC');
  assert.ok(statsGd.includes('export_save_to_txt_file') && statsGd.includes('import_save_from_txt_file'), 'StatsUI.gd must wire .txt export and import');
});

test('OLED 2 FPS mode and interface blackout button are completely removed from AFK mode', () => {
  const forbiddenPatterns = [
    /\bAFK_FPS_LIMIT\b/,
    /render_loop_enabled/,
    /BlackoutButton/,
    /WakeHintLabel/,
    /StyleBoxFlat_blackout_btn/,
    /Погасить интерфейс/,
    /Карманный AFK/,
    /\bOLED\b/,
    /\bAMOLED\b/,
    /\b2 FPS\b/,
  ];

  const activeFiles = [
    ...collectFilesRecursive(path.join(GODOT_ROOT, 'scripts'), '.gd'),
    ...collectFilesRecursive(path.join(GODOT_ROOT, 'scenes'), '.tscn'),
    path.join(GODOT_ROOT, 'CLAUDE.md'),
    path.join(GODOT_ROOT, 'ROADMAP.md'),
  ];

  for (const filePath of activeFiles) {
    const content = fs.readFileSync(filePath, 'utf-8');
    for (const pat of forbiddenPatterns) {
      assert.ok(
        !pat.test(content),
        `Forbidden leftover AFK OLED/2fps reference ${pat} found in ${path.relative(GODOT_ROOT, filePath)}`,
      );
    }
  }

  const afkScene = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/AfkOverlayUI.tscn'), 'utf-8');
  assert.ok(afkScene.includes('🌙 AFK-режим'), 'AfkOverlayUI.tscn should use clean AFK-режим title');
  assert.ok(afkScene.includes('ExitAfkButton'), 'AfkOverlayUI.tscn must retain ExitAfkButton');
});

test('Android freeze optimizations (worker Thread save, O(1) caches, throttled signals, Label pools, coalesced UI) are wired', () => {
  const gmContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  for (const sym of ['const SAVE_THROTTLE_INTERVAL: float = 120.0', '_save_thread', '_wait_for_save_thread', '_save_worker_entry', 'func get_cached_item(', '_ensure_progression_caches', 'emit_signal_immediately']) {
    assert.ok(gmContent.includes(sym), `GameManager.gd must implement ${sym}`);
  }

  const combatContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  assert.ok(combatContent.includes('func _emit_attack_progress('), 'CombatSystem must deduplicate idle attack progress emissions');
  assert.ok(combatContent.includes('_enemy_hud_sync_timer'), 'CombatSystem must throttle enemy continuous HUD updates');

  const arenaGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/BattleArenaUI.gd'), 'utf-8');
  for (const sym of ['_player_popup_pool', '_enemy_popup_pool', '_proj_pool', '_enemy_avatar_style', '_request_hud_refresh']) {
    assert.ok(arenaGd.includes(sym), `BattleArenaUI.gd must implement ${sym}`);
  }

  for (const treeRel of ['scripts/SkillTreeUI.gd', 'scripts/ui/DarkSkillTreeUI.gd']) {
    const treeGd = fs.readFileSync(path.join(GODOT_ROOT, treeRel), 'utf-8');
    assert.ok(treeGd.includes('_style_presets'), `${treeRel} must reuse shared StyleBoxFlat presets`);
    assert.ok(treeGd.includes('_build_graph_once'), `${treeRel} must build graph nodes once instead of rebuilding`);
    assert.ok(treeGd.includes('is_visible_in_tree()'), `${treeRel} must gate updates when hidden`);
  }

  const classGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/ClassUI.gd'), 'utf-8');
  assert.ok(classGd.includes('_build_cards_once') && classGd.includes('is_visible_in_tree()'), 'ClassUI.gd must update cards in place when visible');

  for (const idleProcessRel of ['scripts/ui/StatsUI.gd', 'scripts/ui/DifficultyUI.gd']) {
    const idleGd = fs.readFileSync(path.join(GODOT_ROOT, idleProcessRel), 'utf-8');
    assert.ok(idleGd.includes('set_process(false)'), `${idleProcessRel} must disable _process when confirmation timers are inactive`);
  }

  for (const cachedRel of ['scripts/ui/PetUI.gd', 'scripts/ui/SanctuaryUI.gd']) {
    const cachedGd = fs.readFileSync(path.join(GODOT_ROOT, cachedRel), 'utf-8');
    assert.ok(cachedGd.includes('GameManager.get_cached_item('), `${cachedRel} must use GameManager.get_cached_item instead of raw load()`);
  }

  for (const coalescedRel of [
    'scripts/ui/RightSidebarUI.gd',
    'scripts/ui/ShopUI.gd',
    'scripts/ui/InventoryUI.gd',
    'scripts/ui/EnchantUI.gd',
    'scripts/ui/DarkForgeUI.gd',
    'scripts/ui/DarkShopUI.gd',
    'scripts/ui/PetUI.gd',
    'scripts/ui/SanctuaryUI.gd',
  ]) {
    const cGd = fs.readFileSync(path.join(GODOT_ROOT, coalescedRel), 'utf-8');
    assert.ok(cGd.includes('call_deferred('), `${coalescedRel} must coalesce signal bursts with call_deferred`);
  }
});

test('mobile_theme.tres widens VScrollBar and HScrollBar across project.godot and Main.tscn', () => {
  const themePath = path.join(GODOT_ROOT, 'assets/themes/mobile_theme.tres');
  assert.ok(fs.existsSync(themePath), 'mobile_theme.tres must exist');
  const themeTxt = fs.readFileSync(themePath, 'utf-8');
  assert.ok(themeTxt.includes('VScrollBar/styles/grabber'), 'mobile_theme must customize VScrollBar grabber');
  assert.ok(themeTxt.includes('HScrollBar/styles/grabber'), 'mobile_theme must customize HScrollBar grabber');
  assert.ok(themeTxt.includes('content_margin_left = 10.0') && themeTxt.includes('content_margin_left = 11.0'), 'VScrollBar grabber and track margins must be >= 10px for wider touch scrollbars');
  assert.ok(themeTxt.includes('content_margin_top = 10.0') && themeTxt.includes('content_margin_top = 11.0'), 'HScrollBar grabber and track margins must be >= 10px for wider touch scrollbars');

  const projTxt = fs.readFileSync(path.join(GODOT_ROOT, 'project.godot'), 'utf-8');
  assert.ok(projTxt.includes('theme/custom="res://assets/themes/mobile_theme.tres"'), 'project.godot must register mobile_theme.tres');

  const mainTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/Main.tscn'), 'utf-8');
  assert.ok(mainTscn.includes('res://assets/themes/mobile_theme.tres'), 'Main.tscn must apply mobile_theme.tres');
});

test('base_intellect is trainable, persisted, shown in StatsUI/BattleArenaUI, and HP/Mana use 4x/8x scaling', () => {
  const saveTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/SaveData.gd'), 'utf-8');
  assert.ok(saveTxt.includes('@export var base_intellect: int = 5'), 'SaveData must persist base_intellect with safe default');

  const gmTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  assert.ok(gmTxt.includes('var base_intellect: int = 5'), 'GameManager must define base_intellect');
  assert.ok(gmTxt.includes('float(base_intellect + roundi(get_skill_bonus("intellect"))'), 'get_total_intellect() must include base_intellect and intellect skill bonus');
  assert.ok(gmTxt.includes('case "intellect":') || gmTxt.includes('"intellect":'), 'GameManager must allow training/upgrading intellect');
  assert.ok(gmTxt.includes('float(get_total_endurance()) * 60.0'), 'Max HP must scale by 4x (60.0 per Endurance)');
  assert.ok(gmTxt.includes('float(get_total_endurance()) * 16.0'), 'Max Mana must scale by 8x from Endurance (16.0 per Endurance)');
  assert.ok(gmTxt.includes('float(get_total_intellect()) * 32.0'), 'Max Mana must scale by 8x from Intellect (32.0 per Intellect)');
  assert.ok(gmTxt.includes('var prev_max_hp: float = get_max_hp()'), 'Upgrading stats must add proportional Max HP/Mana delta');

  const statsTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/StatsUI.tscn'), 'utf-8');
  for (const nodeName of ['IntellectRow', 'IntValueLabel', 'IntSPButton', 'IntGoldButton']) {
    assert.ok(statsTscn.includes(nodeName), `StatsUI.tscn must include ${nodeName}`);
  }
  const statsGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/StatsUI.gd'), 'utf-8');
  assert.ok(statsGd.includes('HoldAutoClicker.attach(int_sp_button') && statsGd.includes('HoldAutoClicker.attach(int_gold_button'), 'StatsUI.gd must attach 50/s HoldAutoClicker to Intellect buttons');

  const arenaTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/BattleArenaUI.tscn'), 'utf-8');
  assert.ok(arenaTscn.includes('IntBadgeLabel'), 'BattleArenaUI.tscn must render 4th HUD circle IntBadgeLabel');
  const arenaGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/BattleArenaUI.gd'), 'utf-8');
  assert.ok(arenaGd.includes('int_badge_label.text ='), 'BattleArenaUI.gd must update IntBadgeLabel');
});

test('high-mana high-potency spells (110-260 MP) are registered and HeroMenuUI/SpellbookUI reflect 27 spells', () => {
  const highManaSpells = [
    'arcane_cataclysm.tres',
    'astral_tempest.tres',
    'starfall_oblivion.tres',
    'sacred_revival.tres',
    'archmage_ascension.tres',
    'crimson_apocalypse.tres',
  ];
  for (const file of highManaSpells) {
    const txt = fs.readFileSync(path.join(GODOT_ROOT, 'resources/abilities', file), 'utf-8');
    const mpMatch = /^mana_cost\s*=\s*([0-9.]+)/m.exec(txt);
    assert.ok(mpMatch && parseFloat(mpMatch[1]) >= 110.0, `${file} must have mana_cost >= 110`);
  }

  const gmTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  for (const file of highManaSpells) {
    assert.ok(gmTxt.includes(file), `GameManager.gd must load ${file}`);
  }

  const spellbookTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/SpellbookUI.tscn'), 'utf-8');
  assert.ok(spellbookTscn.includes('19 общих + 7 Архимага Крови + 1 Отражателя'), 'SpellbookUI.tscn must reflect 19 general + 7 Blood Archmage + 1 Reflector spells');
  const heroMenuTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/HeroMenuUI.tscn'), 'utf-8');
  assert.ok(heroMenuTscn.includes('Заклинания (27)'), 'HeroMenuUI.tscn must show 27 spells');
});

test('regular skill tree auto-upgrade preset profiles (3 profiles, preserved across new run) and Bastion of Reflection dark branch are wired', () => {
  const saveTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/SaveData.gd'), 'utf-8');
  for (const field of ['skill_presets', 'active_skill_preset_index', 'skill_auto_upgrade_enabled']) {
    assert.ok(saveTxt.includes(field), `SaveData.gd must persist ${field}`);
  }

  const gmTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  for (const sym of [
    'const SKILL_PRESET_COUNT: int = 3',
    'func toggle_skill_in_active_preset(',
    'func set_active_skill_preset(',
    'func set_skill_auto_upgrade_enabled(',
    'func try_apply_skill_preset(',
    'try_apply_skill_preset(false)',
  ]) {
    assert.ok(gmTxt.includes(sym), `GameManager.gd must implement ${sym}`);
  }

  const skillTreeTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/SkillTreeUI.tscn'), 'utf-8');
  for (const nodeName of ['Preset1Button', 'Preset2Button', 'Preset3Button', 'PresetAutoButton', 'PresetEditButton', 'PresetClearButton', 'PresetToggleNodeButton']) {
    assert.ok(skillTreeTscn.includes(nodeName), `SkillTreeUI.tscn must define ${nodeName}`);
  }
  const skillTreeGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/SkillTreeUI.gd'), 'utf-8');
  assert.ok(skillTreeGd.includes('_node_label_cache') && skillTreeGd.includes('Preset'), 'SkillTreeUI.gd must display #N order badges and wire presets');

  const reflectionNodes = [
    'abyssal_vitality',
    'void_plating',
    'mirror_carapace',
    'obsidian_bulwark',
    'thorn_apotheosis',
  ];
  for (const id of reflectionNodes) {
    assert.ok(fs.existsSync(path.join(GODOT_ROOT, 'resources/dark_skills', `${id}.tres`)), `${id}.tres must exist`);
    assert.ok(gmTxt.includes(`dark_skills/${id}.tres`), `GameManager.gd must register dark_skills/${id}.tres`);
  }
  assert.ok(gmTxt.includes('func get_damage_reflection_pct()'), 'GameManager must expose get_damage_reflection_pct()');

  const combatTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  assert.ok(combatTxt.includes('GameManager.get_damage_reflection_pct()'), 'CombatSystem must apply dark tree damage reflection');
  assert.ok(combatTxt.includes('thorn_apotheosis'), 'CombatSystem must apply thorn_apotheosis 2% Max HP retaliation');
});

test('Alchemist ignores greedy_curse price increases and Blood Archmage casts a random quick-access spell instead of basic hit', () => {
  const gmTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  assert.ok(
    /func get_curse_value\([\s\S]*?curse_id == "greedy_curse" and has_hero_class\("alchemist"\)[\s\S]*?return 0\.0/.test(gmTxt),
    'GameManager.get_curse_value must return 0.0 for greedy_curse when Alchemist is active',
  );

  const alchemistTres = fs.readFileSync(path.join(GODOT_ROOT, 'resources/classes/alchemist.tres'), 'utf-8');
  assert.ok(alchemistTres.includes('иммунитет к дебафу'), 'alchemist.tres must document price-debuff immunity');

  const diffUiGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/DifficultyUI.gd'), 'utf-8');
  assert.ok(diffUiGd.includes('GameManager.class_changed.connect'), 'DifficultyUI must refresh when hero class changes');
  assert.ok(diffUiGd.includes('greedy_curse') && diffUiGd.includes('has_hero_class("alchemist")'), 'DifficultyUI must annotate Alchemist immunity on greedy_curse');

  const enchantUiGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/EnchantUI.gd'), 'utf-8');
  assert.ok(enchantUiGd.includes('иммунитет к дебафу цен'), 'EnchantUI must mention Alchemist price-debuff immunity');

  const combatTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  assert.ok(
    combatTxt.includes('const BLOOD_ARCHMAGE_QUICK_CAST_CHANCE: float = 0.10'),
    'CombatSystem must define 10% proc chance for Blood Archmage quick-access spell basic attack',
  );
  assert.ok(
    combatTxt.includes('func _try_cast_random_quick_ability(') && combatTxt.includes('_quick_cast_slots.shuffle()'),
    'CombatSystem must define _try_cast_random_quick_ability reusing _quick_cast_slots',
  );
  assert.ok(
    combatTxt.includes('try_cast_ability(slot_idx, true, true, false, power_scale)'),
    'Blood Archmage random quick-access basic attack must ignore and not lock slot cooldowns',
  );
  assert.ok(
    /func _perform_player_attack\([\s\S]*?has_hero_class\("blood_archmage"\) and randf\(\) < BLOOD_ARCHMAGE_QUICK_CAST_CHANCE[\s\S]*?_try_cast_random_quick_ability\(power_scale\)/.test(combatTxt),
    'CombatSystem._perform_player_attack must trigger random quick-access spell with 10% chance for Blood Archmage',
  );

  const archmageTres = fs.readFileSync(path.join(GODOT_ROOT, 'resources/classes/blood_archmage.tres'), 'utf-8');
  assert.ok(archmageTres.includes('10%') && archmageTres.includes('тычки') && archmageTres.includes('быстрого доступа'), 'blood_archmage.tres must document 10% random quick-access spell basic attack');
  assert.ok(archmageTres.includes('из 27'), 'blood_archmage.tres must reference 27 total spells');

  const statsUiGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/StatsUI.gd'), 'utf-8');
  assert.ok(statsUiGd.includes('has_hero_class("blood_archmage")') && statsUiGd.includes('10%'), 'StatsUI must show 10% Blood Archmage attack style');

  const faqUiGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/FaqUI.gd'), 'utf-8');
  assert.ok(faqUiGd.includes('иммунитет к дебафу увеличения цен') && faqUiGd.includes('с шансом 10% при ударе вместо тычки кастует случайное заклинание'), 'FaqUI must explain both Alchemist and 10% Blood Archmage mechanics');

  const abilityBtnGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/AbilitySlotButton.gd'), 'utf-8');
  assert.ok(abilityBtnGd.includes('set_process(false)') && abilityBtnGd.includes('set_process(true)'), 'AbilitySlotButton must disable _process when idle');

  const arenaGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/BattleArenaUI.gd'), 'utf-8');
  assert.ok(arenaGd.includes('AVATAR_TWEEN_MIN_INTERVAL_MS') && arenaGd.includes('last_size'), 'BattleArenaUI must throttle burst avatar tweens and cache popup theme overrides');
});

test('Reflector stacks +1 Max HP per kill bound to Reflector class, and Dark Shop Coins (repeatable per run) & ultimate % consumables are wired cleanly', () => {
  const saveTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/SaveData.gd'), 'utf-8');
  assert.ok(saveTxt.includes('@export var reflector_kill_hp_stacks: int = 0'), 'SaveData must persist reflector_kill_hp_stacks');
  assert.ok(saveTxt.includes('@export var dark_shop_coins: int = 0'), 'SaveData must persist dark_shop_coins');

  const gmTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  assert.ok(
    /func record_kill\([\s\S]*?has_hero_class\("reflector"\)[\s\S]*?reflector_kill_hp_stacks \+= 1/.test(gmTxt),
    'record_kill() must increment reflector_kill_hp_stacks infinitely only while Reflector is active',
  );
  assert.ok(
    /func get_max_hp\([\s\S]*?elif has_hero_class\("reflector"\):[\s\S]*?float\(reflector_kill_hp_stacks\)[\s\S]*?total_hp_gain \* 20\.0/.test(gmTxt),
    'get_max_hp() must scope reflector_kill_hp_stacks strictly inside has_hero_class("reflector") and apply 20x HP gain scaling',
  );
  assert.ok(
    /func on_final_boss_defeated\([\s\S]*?var coins_gained: int = maxi\(1, difficulty_level\)[\s\S]*?dark_shop_coins \+= coins_gained/.test(gmTxt),
    'on_final_boss_defeated() must repeatedly award Dark Shop Coins equal to difficulty_level',
  );
  const initRunMatch = /func _init_run_state\([^)]*\) -> void:\n([\s\S]*?)\nfunc start_new_run/.exec(gmTxt);
  assert.ok(initRunMatch, 'GameManager.gd must define _init_run_state()');
  assert.ok(
    !initRunMatch[1].includes('dark_shop_coins = 0') && !initRunMatch[1].includes('reflector_kill_hp_stacks = 0'),
    '_init_run_state() must preserve dark_shop_coins and reflector_kill_hp_stacks across runs',
  );

  const darkShopItems = [
    'dark_ambrosia_vial.tres',
    'void_berserk_draught.tres',
    'abyss_archmage_elixir.tres',
    'titan_bastion_serum.tres',
    'crimson_immortality_orb.tres',
    'cataclysm_apotheosis_flask.tres',
  ];
  for (const file of darkShopItems) {
    const itemPath = path.join(GODOT_ROOT, 'resources/items', file);
    assert.ok(fs.existsSync(itemPath), `${file} must exist`);
    const itemTxt = fs.readFileSync(itemPath, 'utf-8');
    assert.ok(/^dark_shop_coin_price\s*=\s*[1-9]\d*$/m.test(itemTxt), `${file} must define cheap dark_shop_coin_price >= 1`);
    assert.ok(!/^is_dark_forged\s*=\s*true$/m.test(itemTxt), `${file} must NOT be permanent across runs (bought consumables reset on new run)`);
    assert.ok(gmTxt.includes(`items/${file}`), `GameManager.gd must register ${file}`);
  }

  assert.ok(fs.existsSync(path.join(GODOT_ROOT, 'scenes/DarkShopUI.tscn')), 'DarkShopUI.tscn must exist');
  const darkShopGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/DarkShopUI.gd'), 'utf-8');
  assert.ok(darkShopGd.includes('buy_dark_shop_item') && darkShopGd.includes('is_visible_in_tree()'), 'DarkShopUI.gd must call buy_dark_shop_item and gate visibility');

  const heroMenuTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/HeroMenuUI.tscn'), 'utf-8');
  assert.ok(heroMenuTscn.includes('OpenDarkShopButton') && heroMenuTscn.includes('DarkShopUI'), 'HeroMenuUI.tscn must embed DarkShopUI');
  const villageTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/VillageMapUI.tscn'), 'utf-8');
  assert.ok(villageTscn.includes('GoDarkShopButton'), 'VillageMapUI.tscn must link to DarkShopUI');
  const classUiGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/ClassUI.gd'), 'utf-8');
  assert.ok(classUiGd.includes('reflector_kill_hp_stacks'), 'ClassUI.gd must show Reflector kill HP stacks');
});

test('next-boss-without-reset mechanic is completely removed across scripts and scenes (only SaveData legacy field retained)', () => {
  const saveTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/SaveData.gd'), 'utf-8');
  assert.ok(saveTxt.includes('@export var auto_advance_next_boss: bool = false'), 'SaveData must retain inert auto_advance_next_boss for save compatibility');

  const gmTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  for (const removedSym of [
    'next_boss_advanced',
    'can_advance_to_next_boss',
    'set_auto_advance_next_boss',
    'advance_to_next_boss_in_run',
  ]) {
    assert.ok(!gmTxt.includes(removedSym), `GameManager.gd must NOT contain removed symbol ${removedSym}`);
  }

  const combatTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  assert.ok(!combatTxt.includes('_pending_boss_duel') && !combatTxt.includes('_on_next_boss_advanced') && !combatTxt.includes('advance_to_next_boss_in_run'), 'CombatSystem must NOT contain next-boss-without-reset logic');

  const arenaTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/BattleArenaUI.tscn'), 'utf-8');
  assert.ok(!arenaTscn.includes('NextBossButton'), 'BattleArenaUI.tscn must NOT expose NextBossButton');
  const arenaGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/BattleArenaUI.gd'), 'utf-8');
  assert.ok(!arenaGd.includes('next_boss_button') && !arenaGd.includes('next_boss_advanced'), 'BattleArenaUI.gd must NOT reference next-boss-without-reset');

  const diffTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/DifficultyUI.tscn'), 'utf-8');
  assert.ok(!diffTscn.includes('NextBossButton') && !diffTscn.includes('AutoAdvanceButton'), 'DifficultyUI.tscn must NOT expose NextBossButton or AutoAdvanceButton');
  const diffGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/DifficultyUI.gd'), 'utf-8');
  assert.ok(!diffGd.includes('next_boss_started') && !diffGd.includes('advance_to_next_boss_in_run'), 'DifficultyUI.gd must NOT reference next-boss-without-reset');

  const heroMenuGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/HeroMenuUI.gd'), 'utf-8');
  assert.ok(!heroMenuGd.includes('next_boss_started'), 'HeroMenuUI.gd must NOT connect next_boss_started');
});

test('Blood Archmage gets 2x intellect and 3x mana per intellect, and README.md reflects CHANGELOG.md', () => {
  const gmTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  assert.ok(
    /func get_total_intellect\([\s\S]*?elif has_hero_class\("blood_archmage"\):\s*\n\s*total \*= 2\.0/.test(gmTxt),
    'get_total_intellect() must double intellect (2x) when Blood Archmage is active',
  );
  assert.ok(
    /func get_max_mana\([\s\S]*?var mana_from_int: float = float\(get_total_intellect\(\)\) \* 32\.0[\s\S]*?if has_hero_class\("blood_archmage"\):\s*\n\s*mana_from_int \*= 3\.0/.test(gmTxt),
    'get_max_mana() must grant 3x mana from intellect (96 MP/int) when Blood Archmage is active',
  );

  const archmageTres = fs.readFileSync(path.join(GODOT_ROOT, 'resources/classes/blood_archmage.tres'), 'utf-8');
  assert.ok(archmageTres.includes('2x') && archmageTres.includes('в 3 раза больше') && archmageTres.includes('96 MP'), 'blood_archmage.tres must document 2x intellect and 3x mana from intellect');

  const statsGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/StatsUI.gd'), 'utf-8');
  assert.ok(statsGd.includes('2x Инта') && statsGd.includes('3x MP/Инта'), 'StatsUI.gd must display Blood Archmage 2x Int / 3x MP per Int');

  const faqGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/FaqUI.gd'), 'utf-8');
  assert.ok(faqGd.includes('2x прирост Инты') && faqGd.includes('3x маны от Инты'), 'FaqUI.gd must document Blood Archmage 2x Int and 3x mana from Int');

  const changelogTxt = fs.readFileSync(path.join(GODOT_ROOT, 'CHANGELOG.md'), 'utf-8');
  assert.ok(changelogTxt.includes('## [0.21.0]') && changelogTxt.includes('## [0.23.0]'), 'CHANGELOG.md must include [0.21.0] and [0.23.0] entries');

  const readmeTxt = fs.readFileSync(path.resolve(GODOT_ROOT, '../README.md'), 'utf-8');
  assert.ok(!readmeTxt.includes('2 FPS') && !readmeTxt.includes('34 узлов'), 'README.md must not contain stale pre-0.17.3 claims');
  for (const keyFeature of ['0.23.0', '2x прирост интеллекта', 'Тёмный магазин', 'Древняя Шахта', '44 узла', '31 постоянный узел', '27 чар', '100 предметов', 'Бестиарий']) {
    assert.ok(readmeTxt.includes(keyFeature), `README.md must include updated feature "${keyFeature}"`);
  }
});

test('v0.22.0 performance optimizations (AFK HUD skip, FPS selector, 20Hz AttackDiamond, stats cache, pooled UIs, menu pause) are wired', () => {
  const gmTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  for (const sym of ['_stats_cache_dirty', 'func mark_stats_dirty()', 'var afk_target_fps: int', 'const AFK_FPS_OPTIONS', 'func set_afk_fps_limit(', 'func set_menu_open(']) {
    assert.ok(gmTxt.includes(sym), `GameManager.gd must implement ${sym}`);
  }

  const saveTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/SaveData.gd'), 'utf-8');
  assert.ok(saveTxt.includes('@export var afk_target_fps: int = 20'), 'SaveData.gd must persist afk_target_fps');

  const arenaGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/BattleArenaUI.gd'), 'utf-8');
  assert.ok(arenaGd.includes('GameManager.is_afk_mode') && arenaGd.includes('GameManager.is_menu_open'), 'BattleArenaUI.gd must skip HUD updates in AFK and pause heavy updates when HeroMenu is open');

  const heroMenuGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/HeroMenuUI.gd'), 'utf-8');
  assert.ok(heroMenuGd.includes('set_menu_open(true)') && heroMenuGd.includes('set_menu_open(false)'), 'HeroMenuUI.gd must toggle arena menu pause state');

  const abilityBtnGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/AbilitySlotButton.gd'), 'utf-8');
  assert.ok(abilityBtnGd.includes('GameManager.is_afk_mode'), 'AbilitySlotButton.gd must skip continuous button repaints while in AFK');

  const afkTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/AfkOverlayUI.tscn'), 'utf-8');
  for (const btn of ['Fps15Button', 'Fps20Button', 'Fps30Button', 'Fps60Button']) {
    assert.ok(afkTscn.includes(btn), `AfkOverlayUI.tscn must expose ${btn}`);
  }
  const afkGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/AfkOverlayUI.gd'), 'utf-8');
  assert.ok(afkGd.includes('set_afk_fps_limit'), 'AfkOverlayUI.gd must wire set_afk_fps_limit');

  const combatTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  assert.ok(combatTxt.includes('_attack_progress_sync_timer < 0.05'), 'CombatSystem.gd must throttle AttackDiamond sync to 20Hz');

  // Pooled UI scripts refactored in v0.22.0 must never use queue_free() in refresh loops.
  for (const pooledRel of [
    'scripts/ui/InventoryUI.gd',
    'scripts/ui/EnchantUI.gd',
    'scripts/ui/DarkForgeUI.gd',
    'scripts/ui/ClassUI.gd',
    'scripts/ui/PetUI.gd',
    'scripts/ui/DifficultyUI.gd',
    'scripts/ui/RightSidebarUI.gd',
    'scripts/ui/BestiaryUI.gd',
  ]) {
    const pGd = fs.readFileSync(path.join(GODOT_ROOT, pooledRel), 'utf-8');
    assert.ok(!pGd.includes('queue_free('), `${pooledRel} must pool/reuse UI nodes instead of calling queue_free()`);
  }
});

test('v0.22.0 gameplay mechanics (Quality/Salvage, Bestiary, Challenges, Loadouts, Merge/Ultimates, Offhand/Barrier, Auto-Route, Well of Greed, Spell Level/Runes, Expeditions/WaveDungeon/Checkpoints) are wired', () => {
  const gmTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  const saveTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/SaveData.gd'), 'utf-8');
  const itemDataTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/ItemData.gd'), 'utf-8');
  const abilityDataTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/AbilityData.gd'), 'utf-8');

  // 1. Quality rolls, Auto-Salvage & Ore Shards
  for (const field of ['auto_salvage_mode', 'auto_salvage_min_quality', 'abyss_ore_shards', 'inventory_qualities', 'inventory_stars', 'equipped_weapon_quality', 'equipped_weapon_stars']) {
    assert.ok(saveTxt.includes(field), `SaveData must persist ${field}`);
  }
  assert.ok(gmTxt.includes('func set_auto_salvage_settings(') && gmTxt.includes('var forged_ores: int = floori(float(abyss_ore_shards) / 10.0)'), 'GameManager must implement auto-salvage & shard smelting');

  // 2. Bestiary (26 enemies)
  assert.ok(fs.existsSync(path.join(GODOT_ROOT, 'scenes/BestiaryUI.tscn')), 'BestiaryUI.tscn must exist');
  assert.ok(gmTxt.includes('const BESTIARY_MILESTONES') && gmTxt.includes('func record_bestiary_kill('), 'GameManager must track Bestiary milestones');
  const bestiaryGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/BestiaryUI.gd'), 'utf-8');
  assert.ok(bestiaryGd.includes('get_bestiary_kills') && bestiaryGd.includes('get_bestiary_damage_bonus'), 'BestiaryUI must display enemy kill milestones');

  // 3. 4 Abyss Challenges
  assert.ok(gmTxt.includes('const CHALLENGE_CATALOG') && gmTxt.includes('speedrun_titan') && gmTxt.includes('no_potions_titan') && gmTxt.includes('staff_master') && gmTxt.includes('naked_ascetic'), 'GameManager must define all 4 Abyss Challenges');
  const diffGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/DifficultyUI.gd'), 'utf-8');
  assert.ok(diffGd.includes('CHALLENGE_CATALOG') && diffGd.includes('_selected_challenge_id'), 'DifficultyUI must allow selecting Challenges before start_new_run');

  // 4. 3 Combat Loadouts
  assert.ok(gmTxt.includes('const LOADOUT_COUNT: int = 3') && gmTxt.includes('func save_combat_loadout(') && gmTxt.includes('func apply_combat_loadout('), 'GameManager must support 3 combat loadouts');
  const heroMenuTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/HeroMenuUI.tscn'), 'utf-8');
  for (const btnName of ['Loadout1ApplyBtn', 'Loadout1SaveBtn', 'Loadout2ApplyBtn', 'Loadout2SaveBtn', 'Loadout3ApplyBtn', 'Loadout3SaveBtn', 'OpenBestiaryButton']) {
    assert.ok(heroMenuTscn.includes(btnName), `HeroMenuUI.tscn must include ${btnName}`);
  }

  // 5. Duplicate Merge & 3 Ultimate Dark Forge items
  assert.ok(gmTxt.includes('func merge_duplicate_item('), 'GameManager must implement merge_duplicate_item');
  const enchantGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/EnchantUI.gd'), 'utf-8');
  assert.ok(enchantGd.includes('merge_duplicate_item') && enchantGd.includes('ItemData.ItemType.OFFHAND'), 'EnchantUI must support duplicate merge and offhand enchanting');
  for (const ultFile of ['eternal_cataclysm_reaver.tres', 'eternal_eclipse_aegis.tres', 'eternal_archon_talisman.tres']) {
    assert.ok(fs.existsSync(path.join(GODOT_ROOT, 'resources/items', ultFile)), `Ultimate item ${ultFile} must exist`);
    assert.ok(gmTxt.includes(ultFile), `GameManager must register ultimate recipe for ${ultFile}`);
  }

  // 6. Offhand (Shields/Talismans) + Barrier + Reflector 1:1 Max HP conversion
  assert.ok(itemDataTxt.includes('OFFHAND') && itemDataTxt.includes('OffhandKind') && itemDataTxt.includes('bonus_barrier'), 'ItemData.gd must define OFFHAND and barrier stats');
  for (const offFile of ['wooden_buckler.tres', 'iron_tower_shield.tres', 'aegis_bulwark_shield.tres', 'apprentice_talisman.tres', 'astral_arcane_talisman.tres']) {
    assert.ok(fs.existsSync(path.join(GODOT_ROOT, 'resources/items', offFile)), `Offhand item ${offFile} must exist`);
  }
  assert.ok(gmTxt.includes('func get_max_barrier(') && gmTxt.includes('get_raw_max_barrier()'), 'GameManager must compute Barrier and convert 1:1 to Max HP for Reflector');
  const reflectorTres = fs.readFileSync(path.join(GODOT_ROOT, 'resources/classes/reflector.tres'), 'utf-8');
  assert.ok(reflectorTres.includes('1:1'), 'reflector.tres must document 1:1 Barrier -> Max HP conversion');

  // 7. Smart Auto-Route
  assert.ok(gmTxt.includes('func set_auto_route_settings(') && gmTxt.includes('func record_location_win_for_auto_route('), 'GameManager must implement Smart Auto-Route');
  const sidebarGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/RightSidebarUI.gd'), 'utf-8');
  assert.ok(sidebarGd.includes('set_auto_route_settings'), 'RightSidebarUI must wire Auto-Route controls');

  // 8. Well of Greed
  assert.ok(gmTxt.includes('func sacrifice_all_gold_to_well(') && gmTxt.includes('func can_sacrifice_to_well('), 'GameManager must implement Well of Greed sacrifice');
  const villageTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/VillageMapUI.tscn'), 'utf-8');
  assert.ok(villageTscn.includes('WellHotspot') && villageTscn.includes('WellOverlay'), 'VillageMapUI.tscn must expose WellHotspot & WellOverlay');

  // 9. Spell Leveling (1..5) & 26 Spell Runes
  assert.ok(abilityDataTxt.includes('const MAX_SPELL_LEVEL: int = 5') && abilityDataTxt.includes('static func get_level_multiplier('), 'AbilityData must define MAX_SPELL_LEVEL = 5');
  assert.ok(gmTxt.includes('const SPELL_RUNES_CATALOG') && gmTxt.includes('func upgrade_ability_with_page(') && gmTxt.includes('func set_ability_rune('), 'GameManager must implement Spell Leveling and Runes');
  const spellbookGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/SpellbookUI.gd'), 'utf-8');
  assert.ok(spellbookGd.includes('upgrade_ability_with_page') && spellbookGd.includes('set_ability_rune') && spellbookGd.includes('SPELL_RUNES_CATALOG'), 'SpellbookUI must expose spell leveling and A/B rune toggles');

  // 10. Pet Expeditions, 10-Wave Dungeon & Mine Checkpoints
  assert.ok(gmTxt.includes('const PET_EXPEDITION_PLANS') && gmTxt.includes('func start_pet_expedition(') && gmTxt.includes('func claim_pet_expedition('), 'GameManager must implement Pet Expeditions');
  assert.ok(gmTxt.includes('const WAVE_DUNGEON_TOTAL_WAVES: int = 10') && gmTxt.includes('func start_wave_dungeon('), 'GameManager must implement 10-Wave Dungeon');
  assert.ok(gmTxt.includes('const MINE_CHECKPOINT_DEPTHS: Array[int] = [10, 25, 50]') && gmTxt.includes('func buy_mine_checkpoint('), 'GameManager must implement Mine Checkpoints [10, 25, 50]');
  const sanctuaryGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/SanctuaryUI.gd'), 'utf-8');
  assert.ok(sanctuaryGd.includes('start_pet_expedition') && sanctuaryGd.includes('claim_pet_expedition'), 'SanctuaryUI must wire Pet Expeditions');
  assert.ok(sidebarGd.includes('start_wave_dungeon') && sidebarGd.includes('buy_mine_checkpoint'), 'RightSidebarUI must wire Wave Dungeon and Mine Checkpoints');

  const changelogTxt = fs.readFileSync(path.join(GODOT_ROOT, 'CHANGELOG.md'), 'utf-8');
  assert.ok(changelogTxt.includes('## [0.22.0]'), 'CHANGELOG.md must include [0.22.0] entry');
});

test('GDScripts have zero SHADOWED_GLOBAL_IDENTIFIER, Control SHADOWED_VARIABLE_BASE_CLASS, or invalid EnemyData accesses', () => {
  const bestiaryGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/BestiaryUI.gd'), 'utf-8');
  assert.ok(bestiaryGd.includes('enemy.enemy_name') && !bestiaryGd.includes('enemy.display_name') && !bestiaryGd.includes('enemy.is_boss'), 'BestiaryUI.gd must use EnemyData.enemy_name and valid boss checks');

  const globalShadowRx = /^\s*(?:var|for)\s+(?:exp|log|pow|sqrt|abs|seed|range|min|max|round|floor|ceil|clamp|lerp|sign|sin|cos|tan|str|int|float|bool|typeof)\b/gm;
  const controlBaseRx = /^\s*(?:var|for)\s+(?:scale|position|global_position|size|custom_minimum_size|name|visible|modulate|self_modulate|theme|tooltip_text|mouse_filter|focus_mode)\b/gm;

  for (const gdPath of collectFilesRecursive(path.join(GODOT_ROOT, 'scripts'), '.gd')) {
    const src = fs.readFileSync(gdPath, 'utf-8');
    const rel = path.relative(GODOT_ROOT, gdPath);
    const gMatch = src.match(globalShadowRx);
    assert.ok(!gMatch, `${rel} must not shadow global identifiers: ${gMatch?.[0] ?? ''}`);

    if (/^extends\s+(Control|ColorRect|PanelContainer|ScrollContainer|VBoxContainer|HBoxContainer|Button|Label|ProgressBar|Line2D|Node2D|CanvasItem|AspectRatioContainer|CenterContainer|MarginContainer)/m.test(src)) {
      const bMatch = src.match(controlBaseRx);
      assert.ok(!bMatch, `${rel} must not shadow Control/Node2D base properties: ${bMatch?.[0] ?? ''}`);
    }
  }
});

test('v0.23.0 features: Reflector rework (20x HP, 0% dodge, pre-armor 99% cap, battle-start aura, +200% spell), 0.25s spawn, 3 Dark Forge ultimates + weapon def, bulk stats, and 0.001% difficulty reset orb', () => {
  const gmTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  const combatTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  const abilityDataTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/AbilityData.gd'), 'utf-8');
  const itemDataTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/resources/ItemData.gd'), 'utf-8');

  // 1. Mirror Apotheosis (+200% reflect exclusive Reflector spell)
  assert.ok(abilityDataTxt.includes('buff_reflect_pct'), 'AbilityData.gd must declare buff_reflect_pct');
  const mirrorApotheosisTxt = fs.readFileSync(path.join(GODOT_ROOT, 'resources/abilities/mirror_apotheosis.tres'), 'utf-8');
  assert.ok(/required_class_id\s*=\s*"reflector"/.test(mirrorApotheosisTxt), 'mirror_apotheosis.tres must require reflector class');
  assert.ok(/buff_reflect_pct\s*=\s*2\.0/.test(mirrorApotheosisTxt), 'mirror_apotheosis.tres must grant +200% (2.0) reflection');
  assert.ok(gmTxt.includes('abilities/mirror_apotheosis.tres'), 'GameManager must register mirror_apotheosis.tres');

  const spellbookGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/SpellbookUI.gd'), 'utf-8');
  assert.ok(spellbookGd.includes('reflector') && spellbookGd.includes('Отражатель'), 'SpellbookUI must style and tag Reflector exclusive spells');

  // 2. Pre-armor dispersion with 99% mitigation cap + overflow reflection
  assert.ok(gmTxt.includes('minf(get_damage_reflection_pct(), 0.99)'), 'get_reflector_mitigation_pct() must cap incoming damage reduction at 99%');
  assert.ok(combatTxt.includes('var mitigated_pct: float = GameManager.get_reflector_mitigation_pct()') && combatTxt.includes('raw_damage * (1.0 - mitigated_pct)'), 'CombatSystem must apply pre-armor dispersion before apply_damage()');

  // 3. Battle-start Reflector Max HP aura trigger
  assert.ok(combatTxt.includes('func _trigger_reflector_aura_pulse()'), 'CombatSystem must extract _trigger_reflector_aura_pulse()');
  assert.ok(/func _spawn_enemy\([\s\S]*?_trigger_reflector_aura_pulse\(\)/.test(combatTxt), 'CombatSystem._spawn_enemy() must immediately trigger Reflector aura pulse at battle start');

  // 4. Reflector 20x HP scaling + 0% dodge
  assert.ok(/func get_dodge_chance\([\s\S]*?has_hero_class\("reflector"\):\s*\n\s*return 0\.0/.test(gmTxt), 'GameManager.get_dodge_chance() must return 0.0 for Reflector');
  assert.ok(/func record_kill\([\s\S]*?20\.0/.test(gmTxt), 'GameManager.record_kill() must heal proportionally for 20x Reflector HP stack');

  // 5. Faster next-battle start (0.25s normal / 0.2s wave dungeon)
  assert.ok(combatTxt.includes('const SPAWN_DELAY: float = 0.25'), 'CombatSystem must set SPAWN_DELAY = 0.25');
  assert.ok(combatTxt.includes('_spawn_timer = 0.2'), 'CombatSystem must set wave dungeon _spawn_timer = 0.2');

  // 6. 3 new Dark Forge ultimate items + equipped weapon bonus_defense
  for (const newUlt of ['eternal_void_bastion_plate.tres', 'eternal_abyss_bulwark.tres', 'eternal_bastion_greatsword.tres']) {
    assert.ok(fs.existsSync(path.join(GODOT_ROOT, 'resources/items', newUlt)), `${newUlt} must exist`);
    assert.ok(gmTxt.includes(newUlt), `GameManager must register Dark Forge recipe for ${newUlt}`);
  }
  assert.ok(/func get_armor_reduction\([\s\S]*?equipped_weapon\.bonus_defense/.test(gmTxt), 'GameManager.get_armor_reduction() must include equipped_weapon.bonus_defense');

  // 7. Bulk stat upgrades (+10, +25, +50, Max)
  for (const sym of ['func upgrade_stat_with_skill_points_bulk(', 'func train_stat_with_gold_bulk(', 'func get_train_bulk_cost(']) {
    assert.ok(gmTxt.includes(sym), `GameManager must implement ${sym}`);
  }
  const statsTscn = fs.readFileSync(path.join(GODOT_ROOT, 'scenes/StatsUI.tscn'), 'utf-8');
  for (const btn of ['StrSP10Button', 'StrSPMaxButton', 'AgiGold25Button', 'EndSP50Button', 'IntGoldMaxButton']) {
    assert.ok(statsTscn.includes(btn), `StatsUI.tscn must expose bulk stat button ${btn}`);
  }
  const statsGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/StatsUI.gd'), 'utf-8');
  assert.ok(statsGd.includes('upgrade_stat_with_skill_points_bulk') && statsGd.includes('train_stat_with_gold_bulk'), 'StatsUI.gd must wire bulk stat upgrade functions');

  // 8. 0.001% drop Difficulty-Reward Reset Orb (preserves max_unlocked_difficulty)
  assert.ok(itemDataTxt.includes('resets_claimed_difficulties'), 'ItemData.gd must declare resets_claimed_difficulties');
  const orbTxt = fs.readFileSync(path.join(GODOT_ROOT, 'resources/items/abyss_difficulty_reset_orb.tres'), 'utf-8');
  assert.ok(/resets_claimed_difficulties\s*=\s*true/.test(orbTxt) && /is_dark_forged\s*=\s*true/.test(orbTxt), 'abyss_difficulty_reset_orb.tres must reset claimed difficulties and persist as dark-forged item');
  assert.ok(gmTxt.includes('const DIFFICULTY_RESET_DROP_CHANCE: float = 0.00001'), 'GameManager must set DIFFICULTY_RESET_DROP_CHANCE = 0.00001 (0.001%)');
  assert.ok(gmTxt.includes('func reset_claimed_difficulties_rewards(') && gmTxt.includes('func roll_difficulty_reset_item_drop('), 'GameManager must implement reset_claimed_difficulties_rewards and roll_difficulty_reset_item_drop');
  assert.ok(combatTxt.includes('roll_difficulty_reset_item_drop'), 'CombatSystem._roll_drops must invoke roll_difficulty_reset_item_drop');
  const invGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/InventoryUI.gd'), 'utf-8');
  assert.ok(invGd.includes('resets_claimed_difficulties') && invGd.includes('Сбросить'), 'InventoryUI.gd must support using the difficulty reset orb');
});

test('v0.24.0 Alchemist Golden Reaction passive adds 5% of current gold to basic/manual attack damage only', () => {
  const gmTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/GameManager.gd'), 'utf-8');
  assert.ok(gmTxt.includes('const ALCHEMIST_GOLD_REACTION_RATIO: float = 0.05'), 'GameManager must define ALCHEMIST_GOLD_REACTION_RATIO = 0.05');
  assert.ok(
    /func get_alchemist_gold_reaction_bonus\(\) -> float:[\s\S]*?has_hero_class\("alchemist"\)[\s\S]*?gold \* ALCHEMIST_GOLD_REACTION_RATIO/.test(gmTxt),
    'GameManager.get_alchemist_gold_reaction_bonus() must return 5% of current gold when Alchemist is active',
  );
  assert.ok(
    /func get_basic_attack_damage\([\s\S]*?get_player_damage\(preview_ammo_ready\) \+ get_alchemist_gold_reaction_bonus\(\)/.test(gmTxt),
    'GameManager.get_basic_attack_damage() must add get_alchemist_gold_reaction_bonus() on top of base weapon damage',
  );
  assert.ok(
    /func get_player_dps\(\) -> float:[\s\S]*?get_basic_attack_damage\(\)/.test(gmTxt),
    'GameManager.get_player_dps() must reflect get_basic_attack_damage()',
  );

  const combatTxt = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  const perfAttackMatch = /func _perform_player_attack\([\s\S]*?\nfunc _perform_enemy_attack/.exec(combatTxt);
  assert.ok(perfAttackMatch, 'CombatSystem must define _perform_player_attack()');
  assert.ok(
    perfAttackMatch[0].includes('get_basic_attack_damage(has_ammo)') &&
      perfAttackMatch[0].includes('get_basic_attack_damage(has_tome)') &&
      perfAttackMatch[0].includes('get_basic_attack_damage(true)'),
    'CombatSystem._perform_player_attack() must use get_basic_attack_damage() for ranged, staff, and melee basic attacks',
  );

  const alchemistTres = fs.readFileSync(path.join(GODOT_ROOT, 'resources/classes/alchemist.tres'), 'utf-8');
  assert.ok(alchemistTres.includes('Золотая реакция') && alchemistTres.includes('5%'), 'alchemist.tres must document Golden Reaction 5% gold passive');

  const classUiGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/ClassUI.gd'), 'utf-8');
  assert.ok(classUiGd.includes('cid == "alchemist"') && classUiGd.includes('Золотая реакция'), 'ClassUI.gd must display live Golden Reaction bonus');

  const statsUiGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/StatsUI.gd'), 'utf-8');
  assert.ok(statsUiGd.includes('get_basic_attack_damage()') && statsUiGd.includes('get_alchemist_gold_reaction_bonus()'), 'StatsUI.gd must display basic attack damage and Golden Reaction bonus');

  const faqUiGd = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/ui/FaqUI.gd'), 'utf-8');
  assert.ok(faqUiGd.includes('Золотая реакция'), 'FaqUI.gd must document Alchemist Golden Reaction');

  const changelogTxt = fs.readFileSync(path.join(GODOT_ROOT, 'CHANGELOG.md'), 'utf-8');
  assert.ok(changelogTxt.includes('## [0.24.0]'), 'CHANGELOG.md must include [0.24.0] entry');
});

test('v0.25.0 Android Release APK CI (Godot 4.7.2-stable + Gradle without debug) is configured securely', () => {
  const presetsPath = path.join(GODOT_ROOT, 'export_presets.cfg');
  assert.ok(fs.existsSync(presetsPath), 'godot_project/export_presets.cfg must exist');
  const presetsTxt = fs.readFileSync(presetsPath, 'utf-8');

  assert.ok(presetsTxt.includes('name="Android"'), 'export_presets.cfg must define Android preset');
  assert.ok(presetsTxt.includes('platform="Android"'), 'export_presets.cfg must target Android platform');
  assert.ok(presetsTxt.includes('gradle_build/use_gradle_build=true'), 'export_presets.cfg must enable Gradle build');
  assert.ok(presetsTxt.includes('gradle_build/export_format=0'), 'export_presets.cfg must export APK format (0)');
  assert.ok(presetsTxt.includes('graphics/opengl_debug=false'), 'export_presets.cfg must disable opengl_debug');
  assert.ok(presetsTxt.includes('keystore/release_password=""'), 'export_presets.cfg must not commit hardcoded release keystore passwords');

  const workflowPath = path.resolve(process.cwd(), '.github/workflows/build-android.yml');
  assert.ok(fs.existsSync(workflowPath), '.github/workflows/build-android.yml must exist');
  const wfTxt = fs.readFileSync(workflowPath, 'utf-8');

  assert.ok(wfTxt.includes("GODOT_TAG: '4.7.2-stable'"), 'Workflow must target Godot 4.7.2-stable');
  assert.ok(wfTxt.includes("GODOT_TEMPLATE_DIR: '4.7.2.stable'"), 'Workflow must target 4.7.2.stable export templates');
  assert.ok(wfTxt.includes('--export-release "Android"'), 'Workflow must run --export-release for Android preset');
  assert.ok(!wfTxt.includes('--export-debug'), 'Workflow must not build debug APKs');
  assert.ok(wfTxt.includes('android_source.zip') && wfTxt.includes('.build_version'), 'Workflow must install Gradle Android build template');
  assert.ok(wfTxt.includes('platforms;android-36') && wfTxt.includes('build-tools;36.1.0'), 'Workflow must install Android 36 SDK and Build-Tools 36.1.0 for Godot 4.7');

  const changelogTxt = fs.readFileSync(path.join(GODOT_ROOT, 'CHANGELOG.md'), 'utf-8');
  assert.ok(changelogTxt.includes('## [0.25.0]'), 'CHANGELOG.md must include [0.25.0] entry');
});

















