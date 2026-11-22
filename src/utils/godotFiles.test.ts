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
  const gmPaths = [...gmContent.matchAll(/"(res:\/\/[^"]+)"/g)].map((m) => m[1]);
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
  assert.equal(skillFiles.length, 34, 'Expected expanded 34-node regular skill tree');
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
  assert.equal(darkFiles.length, 26, 'Expected expanded 26-node dark skill tree');
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

test('spellbook has exactly 20 abilities (14 general + 6 blood_archmage exclusives), max 3 active slots, buffs, and overcharge_burn', () => {
  const abilityFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/abilities'), '.tres');
  assert.equal(abilityFiles.length, 20, 'Expected exactly 20 abilities');

  let bloodExclusiveCount = 0;
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
    if (/^effect_type\s*=\s*"buff"/m.test(txt)) {
      buffCount++;
    }
    if (/^effect_type\s*=\s*"overcharge_burn"/m.test(txt)) {
      hasOverchargeBurn = true;
    }
  }

  assert.equal(bloodExclusiveCount, 6, 'Expected exactly 6 Blood Archmage exclusive abilities');
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

  const combatContent = fs.readFileSync(path.join(GODOT_ROOT, 'scripts/CombatSystem.gd'), 'utf-8');
  assert.ok(combatContent.includes('raw_damage * 0.20'), 'CombatSystem must reflect 20% incoming damage for Reflector');
  assert.ok(combatContent.includes('get_max_hp() * 0.05'), 'CombatSystem must pulse 5% Max HP/s for Reflector');
  assert.ok(combatContent.includes('enemy_max_hp * 0.001'), 'CombatSystem must apply 0.1% enemy Max HP/s rot for Reflector');
  assert.ok(combatContent.includes('start_stun'), 'CombatSystem must trigger start_stun pet effect on enemy spawn');
});

test('all 34 regular skills cost 1 SP with empowered bonuses, XP curve is steepened, and Dark Points are capped at 1 claim per difficulty', () => {
  const skillFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/skills'), '.tres');
  assert.equal(skillFiles.length, 34);

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
  assert.equal(itemFiles.length, 53, 'Expected 53 item resources (including mana/buff/brewed potions, 5 seeds, 5 harvests)');

  const cropFiles = collectFilesRecursive(path.join(GODOT_ROOT, 'resources/crops'), '.tres');
  assert.equal(cropFiles.length, 5, 'Expected 5 Sanctuary crop resources');

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





