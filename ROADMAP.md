# Innovare Data Table — North Star & Roadmap

> Documento-fonte-da-verdade do pacote `innovare_data_table`. Atualize a cada
> avanço (log no final). Estilo e disciplina: mesmo padrão do `innovare_design`.
>
> - **Branch de trabalho:** `feat/adopt-innovare-design`
> - **Ponto de partida congelado:** `main @ 314770e` (PR #1 da `feature/nova` mergeado) — tag `v0.0.18`
> - **NÃO deletar `feature/nova`** — apps consumidores ainda apontam pra ela
> - **Stack:** Flutter `>=3.10` / Dart `>=3.0`
> - **Preview:** `innovare_data_table/example`

---

## 1. Por que existe (o problema que resolvemos)

A maior parte das telas dos apps Innovare (`app-innv-bolao`, `unic-frontend`,
`logos_saas_frontend`, `app-innv-franchise-finance`, `tessera-admin-frontend`) é
**listagem densa de dados**: usuários, transações, pedidos, withdrawals,
auditoria, tickets, etc. Hoje cada tela reinventa:

- Cabeçalho zebrado, hover, scroll horizontal, sticky.
- Filtros (texto, enum, range, data).
- Paginação + ordenação multi-coluna.
- Mobile (cards) vs desktop (tabela).
- Empty/error/loading states.
- Acessibilidade (teclado, screen reader).

O `innovare_data_table` (v0.0.18) já tem **muita coisa pronta** (~3.000 linhas
no widget core, 31 KB de filtros, sticky table, drag-drop, resize, mobile cards,
controller HTTP com cache e realtime, virtual scrolling, performance monitor,
keyboard nav, accessibility utilities). O problema é que:

1. **Não consome o `innovare_design`** → não herda o piso de craft (tokens,
   primitivas, motion, status colors), tem hex hardcoded e densidade artesanal.
2. **Tem dívida estrutural** (realtime com TODOs, page indexing inconsistente,
   5 sistemas de filtro paralelos, sem testes, sem CHANGELOG, README vazio).
3. **Example não comunica o que o pacote sabe fazer** (menu de botões cru,
   `primarySwatch: Colors.blue`, sem dark mode, sem preset selector).

**Meta:** transformar o pacote num componente "Oscar-worthy" — DataTable de
craft que (a) consome o DS, (b) tem regras de negócio sólidas e testadas, e
(c) tem example showcase que vende a primitiva.

---

## 2. A régua (princípios inegociáveis)

### Definition of Done de uma feature do data_table

Uma feature só está pronta quando:

- [ ] Usa **apenas tokens do `innovare_design`** (cor/tipo/espaço/shape/elevação)
      — nenhum hex literal, nenhum `BorderRadius.circular(n)` mágico.
- [ ] Tem **estados completos**: loading (skeleton), vazio, erro, pressed/hover.
- [ ] Tem **motion** (entrada em cascata, mudança de página, sort animado).
- [ ] **Números/dinheiro** com tabular figures (`InnvMoneyText` /
      `InnvTypography.numeric()`).
- [ ] **Contraste** ok em light e dark.
- [ ] Tem **teste** no `test/` (controller, source, filtros, paginação, sort).
- [ ] É demonstrável no **example** com uma página dedicada.
- [ ] **`flutter analyze`: No issues found.**

### Lista do "não faça"

- Cor hex literal (`Color(0x...)`, `Colors.x`) — usar `InnvColorScheme` ou
  `InnvStatusColors`.
- Tamanho de fonte mágico — usar `InnvTypography`.
- `EdgeInsets`/`SizedBox` fora da escala — usar `InnvSpacing`.
- `BorderRadius.circular(n)` mágico — usar `InnvShapeScheme`.
- `Theme.of(context).colorScheme.primary` direto na primitiva — preferir
  `InnvColorScheme` (via adapter) pra herdar o preset do host.
- `Material` widget cru em vez das primitivas (`InnvBadge`, `InnvButton`,
  `InnvEmptyState`, `InnvErrorState`, `InnvSkeleton`).
- TODOs sem dono em código de produção — abrir issue/seção no roadmap.

---

## 3. Estado atual (snapshot técnico)

### O que existe (`lib/src/`)

| Categoria | Arquivos / símbolos |
| --- | --- |
| **Núcleo** | `innovare_data_table.dart` (3.115 linhas — widget + state + config), `data_column_config.dart`, `data_table_responsive.dart`, `data_table_mobile.dart`, `data_table_theme.dart` |
| **Sticky** | `innovare_stick_data_table.dart` (37 KB), `pure_resizable_header_cell.dart`, `resizable_header_cell.dart`, `drag_drop_column.dart` |
| **Data sources** | `data_table_source.dart`, `http_data_table_source.dart`, `data_table_controller.dart`, `data_table_models.dart` |
| **Filtros (5 sistemas)** | `data_table_filters.dart` (31 KB) + `filters/` (filter_models, modern_filters_dialog, quick_filters, smart_filter_pills, unified_filters_bar, unified_filters_controller, filter_pills) |
| **Mobile** | `mobile/mobile_navigation.dart`, `pull_to_refresh.dart`, `touch_gestures.dart` |
| **Performance** | `performance/debounced_operations.dart`, `memory_optimization.dart`, `optimized_data_table.dart`, `performance_monitor.dart`, `virtual_scrolling.dart` |
| **Accessibility** | `accessibility/accessibility_config.dart`, `accessible_widgets.dart`, `high_contrast_theme.dart`, `keyboard_navigation.dart`, `screen_reader_utils.dart` |
| **Keyboard** | `keyboard/focus_manager.dart`, `keyboard_enhanced_table.dart`, `keyboard_help_dialog.dart`, `keyboard_shortcuts.dart` |
| **Outros** | `columns/column_management.dart`, `loading/smart_loading.dart`, `quick_actions/quick_action_config.dart`, `search/enhanced_search_field.dart`, `search/search_config.dart` |

### Gaps mapeados

#### A. Dívida estrutural

1. **`_handleRealtimeUpdate` com 3 TODOs** (`data_table_controller.dart` linhas
   267-277): `insert`/`update`/`delete` chamam `refresh()` em vez de mutação
   granular. Cada evento de websocket → refetch HTTP completo.
2. **Page indexing inconsistente**: `search`/`clearFilters` resetam para
   `page: 1`, `sort`/`addFilter` para `page: 0`. Decidir 0-indexed ou 1-indexed
   e padronizar (`DataTableRequest` precisa documentar).
3. **`innovare_core` apontando para branch DELETADO** `feature/ajustes-connect`
   → todo consumidor precisa de `dependency_overrides`. Trocar para
   `release/2026-05-19_001` (ref que o `app-innv-bolao` e
   `app-innv-franchise-finance` já usam).
4. **README com 21 bytes** (só `# innovare_data_table`).
5. **Sem `CHANGELOG.md`** — versão 0.0.18, zero histórico documentado.
6. **Sem pasta `test/`** — toda essa complexidade sem cobertura.
7. **Sem `ROADMAP.md`** (este arquivo resolve).
8. **`publish_to:` ausente** no `pubspec.yaml` — pode dar warning em apps
   consumidores com git deps.

#### B. Acoplamento Material / não-DS

1. `DataTableColorScheme` (`data_table_theme.dart` L21-35): `success` e
   `warning` são hex fixos (`#4CAF50`, `#FF9800`). Devia derivar de
   `InnvStatusColors`.
2. `DensityConfig` (`data_table_theme.dart` L58-120): reinventa escala
   (12/16/20px) em vez de consumir `InnvSpacing.s2/s4/s6` e `InnvDensity`.
3. `SkeletonLoader` interno (`innovare_data_table.dart` L29-98) — 70 linhas
   reinventando o que `InnvSkeleton` já entrega.
4. Não usa primitivas do DS em lugar nenhum:
   - Busca/filtros → `InnvTextField`.
   - Ações de linha → `InnvButton`.
   - Status cells → `InnvBadge` (`InnvStatusKind`).
   - Empty state → `InnvEmptyState`.
   - Error state → `InnvErrorState`.

#### C. Gaps funcionais

1. **5 sistemas de filtro paralelos** (`columnFilters`, `quickFilters`,
   `advancedFilters`, `unifiedFiltersConfig`, `smartFilterPills`) com
   sobreposição clara. Decisão: convergir para `UnifiedFiltersController` como
   fonte de verdade; os outros viram facades de compatibilidade ou são
   deprecados.
2. **Multi-sort**: `DataTableController.sort` aceita um único par
   `(field, ascending)`, mas armazena em lista. A UI não expõe modificador
   (Shift+click) pra adicionar coluna ao sort. **Implementar.**
3. **Loading triplicado**: `SkeletonLoader` interno + `smart_loading.dart` +
   `virtual_scrolling.dart` skeleton. Convergir num só, baseado em
   `InnvSkeleton`.
4. **Acessibilidade subutilizada**: `accessibility/` tem 5 arquivos mas o
   widget core não os usa por padrão (precisa opt-in manual). Tornar default
   (com escape hatch).
5. **`HttpDataTableSource`** com cache opcional, mas a invalidação de cache
   em writes não é exposta para o consumidor.

#### D. Example incompleto/inconsistente

1. `main.dart`: menu de `ElevatedButton`s com `primarySwatch: Colors.blue`.
   Sem `InnvPreset`, sem dark toggle, sem demonstração das primitivas.
2. Páginas existentes (6): `test_datasource`, `simple_http`, `products`,
   `sales-dashboard`, `empty`, `innovare`. Cada uma com tematização própria.
3. **Faltam páginas** para: realtime updates otimizados, mobile cards
   (responsive), sticky columns puro, server-side puro, error state, virtual
   scrolling, acessibilidade (com `Semantics`), drag-drop columns,
   keyboard-only navigation.

---

## 4. Onde vamos (plano em ondas)

Cada onda é independente, commitável, com `flutter analyze` limpo e (a partir
da Onda 6) testes verdes.

### Onda 0 — Docs + housekeeping `[PRONTO]`

- [x] Criar branch `feat/adopt-innovare-design`.
- [x] Criar este `ROADMAP.md`.
- [x] Reescrever `README.md` (visão, features, getting started, link pra
      example, link pro `innovare_design`).
- [x] Criar `CHANGELOG.md` com histórico até 0.0.18 (extrair de `git log`).
- [x] Adicionar `publish_to: none` no `pubspec.yaml`.
- [x] Fix `innovare_core` ref em `pubspec.yaml`: `feature/ajustes-connect` →
      `release/2026-05-19_001` (alinhar com `app-innv-bolao` e franchise).
- [x] Criar `test/` com smoke test (`flutter test` retorna 0).
- [ ] Criar `.windsurf/` no pacote (rule opcional pra trabalhos futuros).

### Onda 1 — Integração com `innovare_design` `[PRONTO]`

- [x] Adicionar `innovare_design` como dep git no `pubspec.yaml` (ref: `v0.0.1`).
- [x] Criar `lib/src/theme/innovare_design_adapter.dart`:
  - `InnovareDesignToDataTableColorScheme.toDataTableColorScheme()`
    projeta um `InnovareDesignTheme` em `DataTableColorScheme`.
  - Status colors mapeiam para `InnvStatusColors` (`success`/`warning`/
    `danger.content`).
- [x] `data_table_theme.dart`: detectar se `InnovareDesignTheme` está no tree;
      se sim, usar a projeção do adapter; senão, manter `fromTheme` (Material)
      como fallback (retrocompatível).
- [x] `flutter analyze` nos arquivos editados: **No issues found**.
- [x] `flutter test`: **10/10 passed** (incluindo 2 testes de color scheme via
      preset `aurora` + `vibe`).

### Onda 2 — Refator de tema + skeleton `[PRONTO]`

- [x] **`DensityConfig` tokenizado** — adapter ganhou
      `DataTableDensityFromInnv.toInnvDensityConfig({typography})`:
  - Paddings via `InnvSpacing.md/lg/xl` (idênticos aos statics legacy:
    12/16/20 horizontal, 8/12/16 vertical).
  - Row/header heights via fatores `InnvDensity.compact/standard/comfortable`
    (0.85/1.0/1.15).
  - Font sizes via `InnvTypography.bodyMedium`/`labelMedium`; respeita
    `InnvTypography.scale`.
- [x] **`InnovareDataTableTheme.of` injeta densidade tokenizada
      automaticamente** quando `InnovareDesignTheme.maybeOf(context) != null`
      e o consumer não passou `customDensity`. Compat total: apps sem DS
      continuam recebendo `DensityConfig.compact/normal/comfortable` legacy.
- [x] **`SkeletonLoader` virou proxy** — `StatelessWidget` que delega para
      `InnvSkeleton` quando o DS está no tree e cai para um shimmer Material
      `_MaterialSkeletonShimmer` (idêntico ao código legacy) caso contrário.
      API pública intacta.
- [x] `flutter analyze` nos arquivos editados: **No issues found**.
- [x] `flutter test`: **10/10 passed**.
- [ ] **Pendências da Onda 2** (carry-over): `smart_loading.dart` + virtual
      scrolling skeleton ainda mantêm seus próprios shimmer paths. Headers
      e células ainda não consomem `InnvTypography` diretamente (o ganho
      atual chega via `densityConfig.fontSize/headerFontSize`). Migrar
      depois junto da Onda 4 (primitivas nas cells).

### Onda 3 — Gaps estruturais (regras de negócio) `[EM ANDAMENTO]`

#### 3.1 Page indexing `[PRONTO]`

- [x] **1-indexed everywhere**. `DataTableRequest` documenta a convenção e
      asserta `page >= 1`. `DataTableResult.hasPreviousPage` agora `page > 1`,
      `totalPages` retorna `0` para data set vazio. Novos helpers
      `isFirstPage` / `isLastPage`.
- [x] **Bug crítico corrigido**: `LocalDataTableSource.fetch` pulava
      `pageSize` itens na primeira página (`startIndex = page * pageSize`).
      Agora `(page - 1) * pageSize`.
- [x] `DataTableController`: `goToPage` rejeita `page < 1`,
      `sort`/`addFilter`/`removeFilter` resetam para `1` (eram `0`, o que
      após o assert quebraria).
- [x] Factories `HttpDataTableSource.laravel/django/custom` + helper
      `ApiHelpers.parseStandardPagination` + cache preditivo de
      `smart_loading.dart` alinhados.
- [x] `InnovareDataTable._currentPage` inicia em `1`; boundaries de
      `_previousPage`/`_nextPage`/`_getPagedData` ajustados.
      `MobileBottomActionBar.currentPage` agora aceita 1-indexed.
- [x] `test/page_indexing_test.dart`: **20/20 testes verdes** cobrindo
      request defaults, result boundaries, slicing local, controller flows
      e factories HTTP (Laravel + Django).

#### 3.2 Realtime updates otimizados `[PRONTO]`

- [x] `DataTableController` ganhou parâmetro nomeado opcional
      `realtimeKeyExtractor: dynamic Function(T)`.
- [x] `_applyInsert`/`_applyUpdate`/`_applyDelete` implementados:
  - `insert` anexa ao `_currentResult.data` e incrementa `totalCount`.
  - `update` substitui in-place pelo match de key; off-page cai pro
    `refresh()`.
  - `delete` remove por `itemId` (string) ou pela key do `update.item`;
    off-page cai pro `refresh()`.
- [x] Fallback retrocompatível: sem `realtimeKeyExtractor`, update/delete
      continuam fazendo `refresh()` (insert ainda funciona in-place porque
      não precisa de key).
- [x] `test/realtime_updates_test.dart`: **12/12 verdes** cobrindo todos
      os caminhos + fallbacks com um `_FakeSource` que expõe
      `StreamController` e conta `fetch()`.

#### 3.3 Convergência de filtros

- [ ] Decidir `UnifiedFiltersController` como fonte de verdade. Os outros 4
      sistemas viram:
  - `columnFilters` → facade que registra na unified.
  - `quickFilters` → facade.
  - `advancedFilters` → facade.
  - `smartFilterPills` → vira UI display da unified.
  - Marcar deprecados onde aplicável (sem quebrar API).

#### 3.4 Multi-sort UI `[PRONTO]`

- [x] `DataTableController.sortMulti(List<DataTableSort>)` substitui o
      stack inteiro e reseta página para 1.
- [x] `OnSortRequested` typedef compartilhado (campos `field`/`ascending`/
      `additive`). Adicionado a `PureResizableHeaderCell`,
      `ResizableHeaderCell`, `StickyDataTable`.
- [x] Header tap detecta Shift via `HardwareKeyboard.instance
      .logicalKeysPressed` e emite `additive: true`.
- [x] `_SortPriorityBadge` interno em ambos header cells, renderizado
      apenas quando o stack tem ≥ 2 colunas. Mostra 1/2/3 ao lado do
      ícone de direção (cor `primary` do `DataTableColorScheme`).
- [x] `InnovareDataTable._handleSortRequested` aplica regra: additive →
      append-or-toggle; non-additive → reset. Sincroniza `_sortedField`/
      `_isAscending` com o primário pra preservar `widget.onSort` e o
      caminho local `_applySorting`.
- [x] `_applySorting` itera o stack na ordem de prioridade (tie-breakers).
      Bug pré-existente fixado: agora copia a lista antes de `sort()`
      para tolerar `const`/unmodifiable rows.
- [x] `test/multi_sort_test.dart`: **4/4 verdes**.

#### 3.5 Cache invalidation `[PRONTO]`

- [x] `HttpDataTableSource.invalidateCache({where})` público. Sem
      predicate → wipe total (equiv. `clearCache`). Com predicate sobre
      `DataTableRequest` → remoção seletiva.
- [x] Cache refatorado de `Map<String, DataTableResult<T>>` para
      `Map<String, _CachedFetch<T>>` para preservar o request original.
- [x] Getters públicos `cachedRequests` (Iterable) e `cacheLength` para
      diagnóstico e testes.
- [x] `test/cache_invalidation_test.dart`: **4/4 verdes** com fake
      `http.Client` que conta requisições.

### Onda 4 — Primitivas do DS nas cells

- [ ] Helper `InnvBadgeCell` ou `DataColumnConfig.badge(...)` que renderiza
      `InnvBadge` semântica.
- [ ] Helper `DataColumnConfig.action(...)` que renderiza `InnvButton.icon`.
- [ ] `enhanced_search_field.dart`: substituir TextField interno por
      `InnvTextField` (mantendo a API).
- [ ] `EmptyTablePage` / estado vazio do widget core: usar `InnvEmptyState`.
- [ ] Estado de erro: usar `InnvErrorState` com retry.

### Onda 5 — Example showcase `[PARCIAL]`

- [x] `example/lib/shell/app_shell.dart`: `AppShell` (state holder),
      `AppShellScope` (InheritedWidget), `ShellHeader` (toolbar com
      preset selector + dark toggle).
- [x] `main.dart` redesenhado para usar `AppShell` + `HomePage`.
- [x] `MaterialApp` consome `InnvPresets.resolve(preset, brightness)
      .toThemeData()` — flipar o preset re-skin todas as páginas
      vivas (incluindo o `InnovareDataTable` via adapter da Onda 1).
- [x] Dark mode toggle no header.
- [x] `pages/home_page.dart`: landing com grid de cards (3 do Wave 3,
      6 legacy).
- [x] **Showcases novos** (1 por feature de Wave 3):
  - [x] `MultiSortShowcase` — multi-sort Shift+click + painel de stack
        alimentado por `onSortsChanged`.
  - [x] `RealtimeShowcase` — `StreamingEmployeeSource` (extende
        `LocalDataTableSource` com stream + contador de fetches);
        3 botões de mutação + contador visível.
  - [x] `CacheInvalidationShowcase` — fake `http.Client` que conta
        requests + painel mostrando `cachedRequests` + 2 botões
        ("invalidate current page" vs "invalidate all").
- [x] Novo callback público `InnovareDataTable.onSortsChanged(List
      <DataTableSort>)` — necessário para o painel showcase de
      multi-sort espelhar o stack real do widget.
- [ ] Páginas restantes (não bloqueiam a release; podem ser feitas
      em sub-onda dedicada): mobile responsive, sticky columns
      puro, drag & drop + resize, virtual scrolling, loading/error
      states, accessibility, quick actions, status cells via
      `InnvBadge` (depende de Onda 4).

### Onda 6 — Testes

- [ ] `test/data_sources/data_table_controller_test.dart` — paginação,
      sort, filter, refresh, cache, realtime updates otimizados.
- [ ] `test/data_sources/http_data_table_source_test.dart` — mock HTTP,
      cache, invalidação.
- [ ] `test/filters/unified_filters_controller_test.dart` — adição/remoção,
      `isDefault`, persistência.
- [ ] `test/innovare_data_table_widget_test.dart` — renderiza, paginação
      visual, sort visual, multi-sort, selection.
- [ ] `test/theme/innovare_design_adapter_test.dart` — light/dark via 4
      presets, status colors.
- [ ] Meta inicial: **40 testes verdes**.

### Onda 7 — Release

- [ ] Bump `version: 0.1.0` (mudança grande: adoção do DS).
- [ ] Atualizar `CHANGELOG.md`.
- [ ] Merge `feat/adopt-innovare-design` → `main`.
- [ ] Criar tag `v0.1.0` no GitHub.
- [ ] **NÃO deletar `feature/nova`** (apps ainda apontam).
- [ ] Atualizar consumidores (`app-innv-bolao` `pubspec.yaml`):
      `innovare_data_table` ref `feature/nova` → `v0.1.0` e remover override.

### Pós-release: voltar para o bolão

- [ ] Aplicar `InnovareDataTable` polida em `users_list`, `audit_logs`,
      `withdrawals_admin`, `payments_admin`, `pool_admin_participants`,
      `pool_admin_payments` (substituindo `DataTable` cru + helpers locais).
- [ ] Habilitar `innovare_design_lints` no bolão.
- [ ] Matar `lib/shared/design/` (kit paralelo) no bolão.
- [ ] Derivar `bolao_theme.dart` de `BolaoInnvTheme` (eliminar 137 hex).

---

## 5. Decisões em aberto

- **API breaking changes na convergência de filtros**: marcar como `@Deprecated`
  com mensagem que aponta pra `UnifiedFiltersController`, ou remover de vez?
  → Proposta: deprecar em 0.1.0, remover em 0.2.0.
- **Page indexing 0 vs 1**: confirmar com consumidores. → Proposta: 1-indexed
  (humano), com migração documentada no CHANGELOG.
- **Server-side default**: hoje `enableServerSide: false`. Considerar inferir
  do construtor (`withDataSource` → true, default → false). → Já é o caso via
  factory `withDataSource`, mas o widget aceita ambos via `dataSource` direto
  no construtor base. Padronizar.
- **`accessibility/` default-on?** → Proposta: opt-out em vez de opt-in, com
  flag `disableAccessibility` no `InnovareDataTableConfig` se algum consumidor
  precisar.

---

## 6. Como rodar o preview

```powershell
cd C:\Development\Workspaces\Innovare\innovare_data_table\example
flutter pub get
flutter run -d chrome
```

---

## 7. Log de progresso

> Append-only. Data — o que mudou.

- **2026-06-04** — Criada branch `feat/adopt-innovare-design` a partir de
  `main @ 314770e`. Estado atual mapeado (gaps A/B/C/D). Plano em 7 ondas
  definido. Tag `v0.0.18` no GitHub como estado congelado de partida.
- **2026-06-04** — **Onda 0 (housekeeping) + Onda 1 (DS color scheme)
  entregues** (commit `c068c87`). ROADMAP/README/CHANGELOG bootstrap.
  `publish_to: none`, `innovare_core` repinado para
  `release/2026-05-19_001`. Adapter `InnovareDesignToDataTableColorScheme`
  + `InnovareDataTableTheme.of` preferindo o DS. `flutter test`: 3/3
  passed. `flutter analyze` nos arquivos editados: limpo.
- **2026-06-04** — **Onda 2 (densidade + skeleton) entregue**. Adapter
  ganhou `DataTableDensityFromInnv.toInnvDensityConfig({typography})` e
  `resolveDataTableDensityConfigFromInnv(context, density)`. `SkeletonLoader`
  refatorado para `StatelessWidget` que delega ao `InnvSkeleton` quando o DS
  está instalado (e cai para o shimmer Material legacy senão). `flutter test`:
  10/10 passed. `flutter analyze` nos arquivos editados: limpo. Backlog
  pré-existente do `lib/` (206 issues) mantido — não introduzi nenhuma; alvo
  de cleanup virá junto da Onda 4.
- **2026-06-04** — **Sub-onda 3.1 (page indexing) entregue**. Padronização
  1-indexed em `DataTableRequest`/`Result`/`Controller`/`Source`/`Http*`
  factories/`ApiHelpers`/`InnovareDataTable`/`MobileBottomActionBar` +
  `smart_loading`. Bug crítico corrigido em `LocalDataTableSource.fetch`
  (pulava `pageSize` itens na primeira página). Novos helpers
  `isFirstPage`/`isLastPage`. **BREAKING CHANGE** documentada no
  CHANGELOG (apps que passavam `page: 0` precisam migrar). 20 testes novos
  em `test/page_indexing_test.dart`. `flutter test`: 30/30 verdes
  (smoke 10 + page_indexing 20).
- **2026-06-04** — **Sub-onda 3.2 (realtime updates otimizados) entregue**.
  `DataTableController` ganhou parâmetro opcional `realtimeKeyExtractor`.
  Eventos `insert`/`update`/`delete` agora mutam `_currentResult` in-place
  sem refetch HTTP quando há key disponível (ou quando `insert` traz
  payload). Fallback automático para `refresh()` nos demais casos preserva
  retrocompatibilidade. 12 testes novos em `test/realtime_updates_test.dart`
  com `_FakeSource` que conta `fetch()`. `flutter test`: 42/42 verdes
  (smoke 10 + page_indexing 20 + realtime 12).
- **2026-06-04** — **Onda 5 (parcial) — Example showcase reboot entregue**.
  `example/lib/shell/app_shell.dart` novo (AppShell + AppShellScope +
  ShellHeader) com preset selector (aurora/vibe/slate/lumen) + dark
  toggle. `main.dart` enxuto: só `runApp(AppShell(builder: HomePage))`.
  3 showcases novos (multi_sort, realtime, cache_invalidation) — cada
  um exibe a feature da Onda 3 num cenário realista. `HomePage` com
  grid de cards (Material 3 cards do design system). Para sustentar o
  showcase de multi-sort, adicionado o callback público `InnovareData
  Table.onSortsChanged(List<DataTableSort>)`. `flutter test`: **50/50
  ainda verdes** (zero regressão). `flutter analyze` no `example/`:
  zero erros, só infos pré-existentes em páginas legacy.
- **2026-06-04** — **Sub-ondas 3.4 (multi-sort UI) + 3.5 (invalidateCache)
  entregues**. `DataTableController.sortMulti(...)` novo. Header cells
  (`PureResizableHeaderCell`, `ResizableHeaderCell`, `StickyDataTable`)
  ganharam `activeSorts`/`onSortRequested` + detectam Shift via
  `HardwareKeyboard` + renderizam `_SortPriorityBadge` (1/2/3) em
  multi-sort. `_applySorting` itera o stack como tie-breakers (e bug
  pré-existente de `sort` em lista imutável foi corrigido). Cache do
  `HttpDataTableSource` refatorado para `Map<String, _CachedFetch<T>>`
  preservando o `DataTableRequest`, expondo `invalidateCache({where})` +
  `cachedRequests` + `cacheLength`. 8 testes novos (multi_sort 4 + cache
  4 com `http.Client` que conta requisições). `flutter test`: **50/50
  verdes** (smoke 10 + page_indexing 20 + realtime 12 + multi_sort 4 +
  cache 4).
