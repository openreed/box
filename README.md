# OpenReed Box v2

用于包装和日常收纳的参数化 PETG 盒子：**双侧斜面导轨 + 独立按压锁舌**。只有盒体和盖子两个打印件，不需要磁铁、螺丝、销轴或额外弹簧。

![闭合装配](exports/assembled.png)

## 固定与开盖

- 双侧导轨包住盖子的斜边，阻止盖子向上脱离；尾端实体挡墙阻止盖子继续滑入。
- 盖子的弹性臂末端有锁钩。合盖时前侧斜面让弹性臂向内避让，到位后回弹，锁钩的垂直后端面抵住盒体窗口边缘，阻止滑出。
- 锁止靠形状搭接。滑动间隙和解锁手感分别由导轨间隙、弹性臂尺寸控制。
- 合盖后弹性臂回到自然位置，没有设计持续弯曲预紧；闭合时有少量装配游隙。

**打开：**握住盒体，将开口端右侧窗口内的锁舌朝盖子中央按入约 1.3 mm，同时利用前端指槽将盖子向开口端滑出。先滑出约 9 mm 后即可松开锁舌，继续滑动。

**关闭：**将盖子斜边对准导轨，从开口端推入，直到锁舌回弹入槽；轻拉盖子确认已锁住。

盖子完全取下需沿盒子长边留出约 135 mm 空间。这种结构适合桌面收纳；产品若要求在狭窄空间内向上掀盖，需要另一种结构。

## 模型和参数

- 主文件仍为 `box.scad`，依赖原有的 `BOSL2/std.scad`。
- 保留中英文 Customizer 参数分组，以及 `box_body()`、`box_lid()`、`openreed_logo()` 模块。
- 默认内部参数仍为 **132 × 46 × 52 mm**，另有盖子下方 0.30 mm 的装配间隙；默认外形为 **139 × 53 × 59.6 mm**。内部四角保持 10 mm 圆角。
- `inner_length`、`inner_width`、`inner_height` 控制产品净空间；`wall_thickness`、`bottom_thickness`、`top_thickness` 控制实体厚度。
- `rail_depth=2` 控制每侧导轨的搭接深度。
- `slide_clearance=0.30` 是**每侧水平间隙**，两侧合计 0.60 mm；`vertical_clearance=0.30` 是盖子上下各自的间隙。
- `latch_length=28`、`latch_root_thickness=2.0`、`latch_tip_thickness=1.6` 控制解锁弹性。槽端采用 0.9 mm 圆弧，弹性臂沿打印层内的方向弯曲。
- `latch_hook_depth=1.2` 在默认水平间隙下产生 0.90 mm 的横向搭接；`latch_slot_gap=1.8` 留出按压行程，并提供按压限位。
- 旧版位于 `legacy/box-v1.scad`。新旧盒体、盖子不能混用。

`part` 可选：`print`（默认并排打印）、`body`、`lid`、`assembled`、`exploded`、`section`、`fit_test`、`fit_test_body`、`fit_test_lid`。装配预览用 `lid_slide=40` 可显示部分滑开状态；这是静态位置预览，不模拟解锁变形。

## 打印与试配

1. 先打印 `exports/fit_test_body.stl` 和 `exports/fit_test_lid.stl`。试配盒体约 **38 × 53 × 8.1 mm**，复制完整模型的导轨、锁舌、锁止窗口和按压区域，并带定位挡墙。
2. 用实际打印机和 PETG 检查：盖子滑动顺畅；合盖后锁钩回弹；未按压时无法滑出；按压后可以轻松打开。
3. 试配满意后打印 `exports/body.stl` 和 `exports/lid.stl`。STL 是默认参数的导出结果，改参数后需要重新导出。

建议起点：0.4 mm 喷嘴、0.20 mm 层高、4 道墙、5 层顶底、15–20% 填充。盒体底朝下、开口朝上；盖子平坦底面朝下、标识面朝上。模型已经按此方向放置，**设计为无需支撑**：导轨横向生长 2 mm、上升 4.1 mm；盖子及锁舌平放打印。实际免支撑效果仍取决于切片与打印条件。

接缝避开导轨配合面和锁钩。盖子的第一层象脚若造成卡滞，可使用切片软件的象脚补偿；不要让 brim 连住弹性臂与主盖之间的槽。

如果滑动偏紧，先将 `slide_clearance` 从 0.30 增到 0.35 或 0.40，并重新打印试配件。上下夹紧则调整 `vertical_clearance`。如果按压偏硬，可以适当增加 `latch_length`。不要通过削平锁止肩或把锁钩改成退出斜面来调开盖手感。

0.30 mm 是本模型的初始间隙，并非所有 PETG 打印机通用的经验保证。请用试配件确认。完整样件建议进行至少 100 次开合、装载后的倒置和摇晃检查，确认锁舌持续回弹、没有裂纹或自行滑出，再用作正式产品包装。

## 导出和几何验证

在 OpenSCAD 中用 Customizer 选择 `part=body` 或 `part=lid` 后渲染并导出 STL。命令行示例：

```sh
openscad --hardwarnings --backend Manifold --export-format binstl -D 'part="body"' -o exports/body.stl box.scad
openscad --hardwarnings --backend Manifold --export-format binstl -D 'part="lid"' -o exports/lid.stl box.scad
python3 tools/validate.py --openscad /path/to/OpenSCAD
```

已用 OpenSCAD 2025.12.07 / Manifold 验证：

- 四个默认打印件均为封闭、面朝向一致的单一实体，底面位于 Z=0。
- 20 项几何检查通过：闭合间隙、前后挡止、导轨防上掀、试配件锁止，以及解锁后的 13 个滑动位置。
- 80 × 30 × 20 mm、170 × 70 × 60 mm 和较松间隙三组参数均能生成有效实体，闭合时没有干涉。

详细结果见 `exports/validation-report.json`。解锁检查采用向内平移弹性臂的运动包络，**不是有限元变形模拟**。几何检查不代表已经测得保持力、跌落性能、操作手感或疲劳寿命；本次未制作实体样件。

设计参考：[Protolabs 的卡扣设计指南](https://www.hubs.com/knowledge-base/how-design-snap-fit-joints-3d-printing/)（自然锁止位置、圆滑槽根和打印层方向）、[Prusa 的打印建模指南](https://help.prusa3d.com/article/modeling-with-3d-printing-in-mind_164135)和 [PETG 材料说明](https://help.prusa3d.com/article/petg_2059)。本模型的具体尺寸与间隙由几何设计得出，仍需实物试配。
