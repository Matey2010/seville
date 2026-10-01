import 'dart:ui';

import '../../models/layout/layout.dart';
import 'lg_ergo_center_action_row.dart';
import 'lg_ergo_create_node_layout.dart';
import 'lg_ergo_navigation_column.dart';
import 'lg_ergo_game_scene.dart';

final lgErgoPanoramicGrid = GridLayout(
  aliases: [
    'panoramic-grid',
    'panoramic-layout',
    'direction-pad',
    'node-direction-controls',
    'spatial-navigation',
    'panorama',
  ],
  rowsConfig: {
    'top': LayoutSize.fr(1),
    'center': LayoutSize.fr(1),
    'bottom': LayoutSize.fr(1),
    'center-action-row': LayoutSize.rem(3),
    'teletext-ribbon': LayoutDefaultSize.panoramicFooter,
  },
  columnsConfig: {
    'left': LayoutSize.fr(
      1,
      state: LayoutState({
        LayoutCondition.findOpened(): LayoutSize.fr(0.5),
        LayoutCondition.createOpened(): LayoutSize.fr(0.5),
      }),
      animationDuration: Duration(milliseconds: 320),
    ),
    'center': LayoutSize.fr(3),
    'right': LayoutSize.fr(1),
  },
  slots: {
    'point-of-view': GridSlot(
      row: 'top',
      column: 'right',
      rowSpan: 0.25,
      state: LayoutState({
        LayoutCondition.createOpened(): GridSlot(
          row: 'bottom',
          column: 'center',
          rowSpan: 0.25,
          rowOffset: 0.75,
        ),
      }),
      animationDuration: Duration(milliseconds: 420),
    ),
    'boss-ribbon': GridSlot(
      row: 'top',
      column: 'center',
      rowSpan: 0.25,
      columnSpan: 1,
    ),
    'navigation-column': GridSlot(row: 'top', column: 'left'),
    'bottom-left-area': GridSlot(row: 'bottom', column: 'left'),
    // TODO: Remove those slots after 2027
    'info': GridSlot(
      row: 'top',
      column: 'left',
      aliases: ['info-grid'],
      rowSpan: 1,
      rowOffset: 1,
    ),
    'find-layout': GridSlot(
      row: 'top',
      column: 'center',
      columnSpan: 1,
      rowSpan: 3,
    ),
    'create-layout': GridSlot(
      row: 'top',
      column: 'center',
      columnSpan: 1,
      rowSpan: 3,
    ),
    'info-table-slot': GridSlot(
      row: 'top',
      column: 'right',
      rowSpan: GridSpan.full,
      state: LayoutState({
        LayoutCondition.createOpened(): GridSlot(
          row: 'top',
          column: 'right',
          columnSpan: 2,
          rowSpan: 3.5,
          rowOffset: 0.5,
        ),
      }),
      animationDuration: _lgErgoInfoTableTransitionDuration,
    ),
    'game-scene': GridSlot(
      row: 'top',
      column: 'left',
      rowSpan: 3,
      columnSpan: 3,
    ),
    'action-panel': GridSlot(row: 'top', column: 'right', rowSpan: 2),
    'top-left': GridSlot(row: 'top', column: 'left'),
    'top-center': GridSlot(row: 'top', column: 'center'),
    'top-right': GridSlot(row: 'top', column: 'right'),
    'center-left': GridSlot(row: 'center', column: 'left'),
    'center': GridSlot(row: 'center', column: 'center'),
    'center-right': GridSlot(row: 'center', column: 'right'),
    'bottom-left': GridSlot(row: 'bottom', column: 'left'),
    'bottom-center': GridSlot(row: 'bottom', column: 'center'),
    'bottom-right': GridSlot(row: 'bottom', column: 'right'),
    'center-action-row': GridSlot(row: 'center-action-row', column: 'center'),
  },
  children: {
    'pov': PanelLayout(
      state: LayoutState({
        LayoutCondition.mainMenu(): LayoutConfig(visible: true),
      }),
      slot: 'point-of-view',
      aliases: ['header-view-change', 'view-change-shortcut'],
      borderStyle: GuideStyle(
        color: Color(0xFFFFD54F),
        strokeWidth: 1.2,
        pattern: GuideLinePattern.solid,
      ),
      text: LayoutTextConfig(value: LayoutText.value('🎥 pov | p')),
    ),
    'info-grid': TableLayout(
      state: LayoutState({
        LayoutCondition.mainMenu(): LayoutConfig(visible: true),
      }),
      slot: 'info-table-slot',
      aliases: [
        'info-grid',
        'info-table',
        'info-panel',
        'info-pane',
        'info-plane',
        'left-plane',
        'west-plane',
        'table-layout',
        'node-info',
        'system-info',
      ],
      background: [
        LayoutBackground.image(
          assetPath: 'assets/wallpapers/daft-punk-suit.jpg',
          fit: LayoutBackgroundFit.fill,
          opacity: 0.84,
        ),
      ],
      layoutBorderWidth: 1.8,
      guideStyle: GuideStyle(
        color: Color(0x665F7CFF),
        strokeWidth: 1,
        pattern: GuideLinePattern.solid,
      ),
      cellHighlight: TableCellHighlightConfig(
        rows: true,
        // columns: true,
        color: Color(0x66374A9B),
      ),
      includeUnconfiguredFields: true,
      unconfiguredFieldPanelId: 'last_selected_node',
      panelGap: 12.0,
      panelBorderStyle: GuideStyle(
        color: Color(0xAA5F7CFF),
        strokeWidth: 1.4,
        pattern: GuideLinePattern.solid,
      ),
      tableConfig: TableConfig(
        panels: {
          'last_selected_node': PanelConfig(
            orderPosition: 0,
            title: 'Last Selected Node',
            foldable: true,
          ),
          'updates': PanelConfig(
            orderPosition: 2,
            title: 'Updates',
            foldable: true,
          ),
          'selected_nodes': PanelConfig(
            orderPosition: 3,
            title: 'Selected Nodes',
            foldable: true,
          ),
          'system': PanelConfig(
            orderPosition: 6,
            title: 'System',
            foldable: true,
            initiallyFolded: true,
          ),
        },
        rowConfig: TableRowConfig(
          rows: {
            'slug': TableRow(
              orderPosition: 0,
              label: 'Slug',
              panelId: 'last_selected_node',
              size: LayoutSize.fr(1),
              actions: [TableAction.copyToClipboard()],
            ),
            'labels': TableRow(
              orderPosition: 1,
              label: 'Labels',
              panelId: 'last_selected_node',
              size: LayoutSize.fr(1),
            ),
            'classification': TableRow(
              orderPosition: 2,
              panelId: 'last_selected_node',
              size: LayoutSize.fr(1),
            ),
            'version': TableRow(
              orderPosition: 3,
              panelId: 'last_selected_node',
              size: LayoutSize.fr(0.5),
            ),
            'selected_node_slugs': TableRow(
              orderPosition: 0,
              label: 'Slugs',
              panelId: 'selected_nodes',
              size: LayoutSize.fr(1),
            ),
            'selected_node_labels': TableRow(
              orderPosition: 1,
              label: 'Labels',
              panelId: 'selected_nodes',
              size: LayoutSize.fr(1),
            ),
            'added': TableRow(
              orderPosition: 0,
              label: 'Added',
              panelId: 'updates',
              includeWhenEmpty: true,
              size: LayoutSize.fr(1),
            ),
            'updated': TableRow(
              orderPosition: 1,
              label: 'Updated',
              panelId: 'updates',
              includeWhenEmpty: true,
              size: LayoutSize.fr(1),
            ),
            'deleted': TableRow(
              orderPosition: 2,
              label: 'Deleted',
              panelId: 'updates',
              includeWhenEmpty: true,
              size: LayoutSize.fr(1),
            ),
            'node_count': TableRow(
              orderPosition: 0,
              label: 'Nodes',
              panelId: 'system',
              size: LayoutSize.fr(1),
            ),
            'neo4j_labels': TableRow(
              orderPosition: 1,
              label: 'Trending Labels',
              panelId: 'system',
              size: LayoutSize.fr(1),
            ),
            'node_property_count': TableRow(
              orderPosition: 2,
              label: 'Node properties',
              panelId: 'system',
              size: LayoutSize.fr(1),
            ),
            'go_version': TableRow(
              orderPosition: 3,
              label: 'Go version',
              panelId: 'system',
              size: LayoutSize.fr(1),
            ),
            'neo4j_version': TableRow(
              orderPosition: 4,
              label: 'Neo4j version',
              panelId: 'system',
              size: LayoutSize.fr(1),
            ),
          },
        ),
        columnConfig: TableColumnConfig(
          columns: {
            'key': TableColumn(size: LayoutSize.fr(1)),
            'value': TableColumn(size: LayoutSize.fr(3)),
          },
        ),
      ),
      children: {
        'added': NodeListLayout(
          dataSource: NodeListDataSource.virtualNodes,
          style: GuideStyle(
            color: Color(0xFFFFF7D6),
            strokeWidth: 1.8,
            pattern: GuideLinePattern.solid,
          ),
          layoutBorderWidth: 1.8,
          aliases: ['virtual-nodes', 'draft-nodes', 'uncreated-nodes'],
        ),
      },
    ),
    'find-layout': FindLayout(
      slot: 'find-layout',
      aliases: ['find-layout', 'node-finder', 'search-layout'],
      background: [LayoutBackground.color(Color(0xF2283252))],
      text: LayoutTextConfig(fontSize: 18),
      layoutBorderWidth: 1.8,
      state: LayoutState({
        LayoutCondition.findOpened(): LayoutConfig(visible: true),
      }),
      children: {
        FindLayout.resultsLayoutKey: ColumnLayout(
          slot: FindLayout.resultsLayoutKey,
          aliases: ['search-results', 'search-results-column'],
          text: LayoutTextConfig(flow: LayoutTextFlow.horizontal()),
          children: {
            'search_results': NodeListLayout(
              dataSource: NodeListDataSource.searchResults,
              style: GuideStyle(
                color: Color(0xFFFFF7D6),
                strokeWidth: 1.8,
                pattern: GuideLinePattern.solid,
              ),
              layoutBorderWidth: 1.8,
              node: const NodeConfig(
                slugPrefix: '[[',
                slugTransform: TextTransform.capitalCap(),
                slugSuffix: ']]',
              ),
            ),
          },
        ),
      },
    ),
    'create-layout': lgErgoCreateNodeLayout,
    'game-scene': lgErgoGameScene,
    'navigation-column': lgErgoNavigationColumn,
    'center-action-row': lgErgoCenterActionRow,
    'teletext': PanelLayout(
      slot: 'teletext',
      aliases: [
        'bottom-ribbon',
        'scene-ribbon',
        'teletext-ribbon',
        'poloska-teletexta',
        'teletext-bottom',
      ],
      text: LayoutTextConfig(
        value: LayoutText.value(
          'teletext | 🌌 | ☀️ | 🌎 | 🇪🇸 | BCN | 2026 | ⛱️ Jun - Jul - Aug | XX | XX:XX | ↕️ 2REM'
          '| ↕️ 2REM',
        ),
        color: Color(0xFF21FFF3),
        fontSize: 12,
      ),
      borderStyle: GuideStyle(
        color: Color(0xFFFFD54F),
        strokeWidth: 1.2,
        pattern: GuideLinePattern.solid,
      ),
      background: [
        // LayoutBackground.color(Color(0xCC283252)),
        LayoutBackground.image(
          assetPath: 'assets/wallpapers/dark-vintage-scheme.jpg',
          fit: LayoutBackgroundFit.cover,
          orderPosition: 1,
        ),
      ],
    ),
  },
);

const _lgErgoInfoTableTransitionDuration = Duration(milliseconds: 420);
