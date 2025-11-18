# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

# Production Management System - Architecture Guide

This document provides a comprehensive overview of the Production Management System for future Claude instances.

## Project Overview

**Type**: Ruby on Rails Web Application (Manufacturing/Production Management System)
**Purpose**: Comprehensive production management system for manufacturing operations including inventory, recipes, equipment, and production planning
**Language**: Korean (한국어)
**Domain**: Food/Bakery production management (특히 제빵/제과 관련)

## Technology Stack

### Backend
- **Framework**: Ruby on Rails 8.1.1
- **Ruby Version**: 3.4.7
- **Database**: SQLite3 (with multi-database support in production)
- **Asset Pipeline**: Propshaft
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable

### Frontend
- **JavaScript**: ES6+ with Import Maps
- **CSS Framework**: Bootstrap 5.3.8 (customized with Apple-style design)
- **CSS Preprocessor**: SASS (SCSS)
- **Build Tools**: 
  - PostCSS with Autoprefixer
  - cssbundling-rails
- **JavaScript Libraries**:
  - Hotwire (Turbo + Stimulus)
  - Bootstrap 5 + Popper.js
  - Bootstrap Icons 1.13.1
  - Flatpickr (date picker)
  - QuaggaJS (barcode scanning)
  - SortableJS (drag & drop)
- **Node Version**: 24.11.1

### Development & Testing
- **Test Framework**: Minitest with System Tests (Capybara + Selenium)
- **Security Tools**: Brakeman, Bundler Audit
- **Code Style**: RuboCop Rails Omakase
- **Deployment**: Kamal (Docker-based), Thruster

## Directory Structure

```
production-management-system/
├── app/
│   ├── assets/
│   │   ├── builds/           # Compiled CSS output
│   │   └── stylesheets/      # SCSS source files
│   ├── controllers/          # Application controllers
│   │   ├── inventory/        # Inventory module controllers
│   │   └── production/       # Production module controllers
│   ├── javascript/           # JavaScript files
│   │   ├── controllers/      # Stimulus controllers
│   │   ├── application.js    # Main JS entry point
│   │   └── interactions.js   # Custom interaction helpers
│   ├── models/               # ActiveRecord models
│   └── views/                # ERB view templates
│       ├── inventory/
│       ├── production/
│       ├── recipes/
│       ├── finished_products/
│       ├── equipments/
│       └── layouts/
├── bin/                      # Executable scripts
├── config/
│   ├── routes.rb            # Application routes
│   ├── database.yml         # Database configuration
│   ├── importmap.rb         # JavaScript imports
│   └── application.rb       # Application configuration
├── db/
│   ├── migrate/             # Database migrations (45+ files)
│   └── schema.rb            # Current database schema
├── lib/                     # Custom libraries
├── public/                  # Static assets
├── storage/                 # SQLite databases & Active Storage
├── test/                    # Test suite
└── vendor/                  # Third-party code
```

## Core Domain Models

### 1. Inventory Management (재고 관리)
- **Item** (`items`): 품목 정보
  - Auto-generated item codes (ITEM-0001, ITEM-0002...)
  - Barcode support
  - Stock level calculations (minimum, optimal)
  - Weight tracking
  - Supplier management (JSON array)
  - Configurable categories (via `ItemCategory`)
  - Configurable storage locations (via `StorageLocation`)
  
- **Receipt** (`receipts`): 입고 내역
  - Quantity, unit price
  - Manufacturing & expiration dates
  - Supplier information
  - Unit weight tracking

- **Shipment** (`shipments`): 출고 내역
  - Configurable purposes and requesters
  - Date tracking
  - Notes

- **ShipmentPurpose** / **ShipmentRequester**: 출고 목적 및 요청자 설정
  - Position-based ordering (drag & drop)

### 2. Recipe Management (레시피 관리)
- **Recipe** (`recipes`): 레시피
  - Name, description, notes
  - Ingredients (many-to-many with items)
  - Equipment requirements
  - Weight calculations (main ingredients, subtotals)
  - **Automatic version tracking on updates**

- **RecipeVersion** (`recipe_versions`): 레시피 버전 관리
  - Complete snapshot of recipe data (JSON)
  - Change summary tracking
  - Version numbering
  - Changed by/at tracking

- **RecipeIngredient** (`recipe_ingredients`): 레시피-재료 연결
  - Weight tracking
  - Main ingredient flag
  - Row types: 'ingredient' or 'subtotal'
  - Position-based ordering

- **RecipeEquipment** (`recipe_equipments`): 레시피-장비 연결
  - Work capacity tracking
  - Process grouping
  - Row types for grouping

### 3. Ingredient Composition (재료 구성)
- **Ingredient** (`ingredients`): 재료 정보
  - Production quantity/unit
  - Cooking time
  - Equipment type & mode associations
  - Sub-items composition
  - **Unit conversion**: All quantities auto-convert to grams for totals

- **IngredientItem** (`ingredient_items`): 재료-품목 연결
  - Quantity tracking with automatic gram conversion (Kg×1000, L×1000, mL×1)
  - Custom names
  - Can reference other ingredients (recursive)
  - Row types: 'item', 'ingredient', 'subtotal'
  - Source types: 'item' (品目), 'ingredient' (재료), 'other' (기타)

### 4. Finished Products (완제품)
- **FinishedProduct** (`finished_products`): 완제품
  - Name, description
  - Total weight calculation
  - Multiple recipes composition

- **FinishedProductRecipe**: 완제품-레시피 연결
  - Quantity per recipe
  - Position-based ordering

### 5. Production Planning (생산 관리)
- **ProductionPlan** (`production_plans`): 생산 계획
  - Production date
  - Quantity
  - Linked to finished product

- **ProductionLog** (`production_logs`): 반죽일지 (Dough/Production Log)
  - Detailed production metrics:
    - Temperature tracking (dough, flour, water, porridge)
    - Room temperature (fermentation, refrigeration)
    - Ingredient amounts (makgeolli, yeast, sugar, salt, stevia, water)
    - Dough count
  - Linked to production plan and finished product

### 6. Equipment Management (장비 관리)
- **Equipment** (`equipment`): 장비
  - Name, manufacturer, model
  - Capacity tracking
  - Status: 정상, 점검중, 고장, 폐기
  - Location, purchase date

- **EquipmentType** (`equipment_types`): 장비 구분
  - Position-based ordering

- **EquipmentMode** (`equipment_modes`): 장비 모드
  - Belongs to equipment type
  - Position-based ordering

- **RecipeProcess** (`recipe_processes`): 공정 관리
  - Process names for recipe equipment grouping


## Key Routes & Endpoints

### Main Modules
- Root: `GET /` → `home#index`
- Settings: `GET /settings` and `GET /settings/system`

### Production Module
```ruby
GET  /production
namespace :production do
  resources :plans      # 생산 계획
  resources :logs       # 반죽일지
end
```

### Inventory Module
```ruby
GET  /inventory
namespace :inventory do
  resources :receipts   # 입고
  resources :shipments  # 출고
  resources :items      # 품목 관리
    GET :find_by_barcode
    GET :suppliers
    POST :add_supplier
  resources :stocks, only: [:index]  # 재고 현황
end
```

### Recipe Module
```ruby
GET  /recipe
resources :recipes do
  PATCH :update_ingredient_positions
  resources :recipe_versions, only: [:index]
end
```

### Other Resources
```ruby
resources :ingredients        # 재료 관리
resources :equipments        # 장비 관리
resources :finished_products # 완제품 관리
```

## Database Schema Highlights

### Important Features
1. **Cascade Deletes**: All recipe-related foreign keys have `ON DELETE CASCADE` to maintain data integrity
2. **Position-based Ordering**: Many tables use `position` column for drag & drop ordering
3. **JSON Storage**: Recipe versions store complete snapshots in JSON format
4. **Serialization**: Items table uses JSON array for suppliers
5. **Multi-database**: Production environment uses separate databases for cache, queue, and cable

### Key Relationships
- Recipe → RecipeIngredients → Items
- Recipe → RecipeEquipments → Equipment
- Recipe → RecipeVersions (version history)
- Recipe → FinishedProductRecipes → FinishedProducts
- FinishedProduct → ProductionPlans → ProductionLogs
- Ingredient → IngredientItems → Items
- Ingredient → IngredientItems → Ingredients (self-referential)

## Frontend Architecture

### Design System
- **Style**: Apple-refined design system
- **Color Palette**: Custom refined colors (sapphire, emerald, amber, crimson, etc.)
- **Fonts**: 
  - Space Grotesk (headings, 600-700 weight)
  - Inter (body text, 300-700 weight)
- **Components**: Card-based, glassmorphism effects, smooth animations
- **Responsive**: Mobile-first with breakpoints at 576px, 768px, 991px, 1200px

### JavaScript Architecture
```
application.js (entry point)
├── @hotwired/turbo-rails    # Turbo Drive, Frames, Streams
├── controllers              # Stimulus controllers
├── bootstrap                # Bootstrap 5 bundle
└── interactions             # Custom helpers
```

### Custom Interaction Helpers (`interactions.js`)
Global utilities available throughout the application:

- **ToastManager** (`window.toast`)
  - `toast.success(message, title)` - Green success notification
  - `toast.error(message, title)` - Red error notification
  - `toast.warning(message, title)` - Amber warning notification
  - `toast.info(message, title)` - Blue info notification

- **LoadingManager** (`window.loading`)
  - `loading.show()` - Display full-screen loading overlay
  - `loading.hide()` - Hide loading overlay

- **Form Helpers**
  - `setButtonLoading(button, isLoading)` - Toggle button loading state
  - `validateForm(formElement)` - Validate all required fields
  - `confirmDialog(message, title)` - Promise-based confirmation dialog

- **Utility Functions**
  - `debounce(func, wait)` - Debounce function calls
  - `smoothScrollTo(element)` - Smooth scroll to element

### External Libraries
- **Flatpickr**: Korean locale date/time picker
- **QuaggaJS**: Barcode scanning via camera
- **SortableJS**: Drag & drop for position management (used in views)

## Development Workflow

### Setup & Installation
```bash
# Install dependencies
bundle install
yarn install

# Database setup
bin/rails db:create db:migrate db:seed

# Start development server
bin/dev  # Runs both Rails server & CSS watch
```

### Development Commands
```bash
# Start Rails server (port 3000)
bin/rails server

# Watch CSS changes (auto-compiles on save)
yarn watch:css

# Build CSS manually
yarn build:css

# Run tests
bin/rails test              # All tests
bin/rails test:system       # System tests only

# Database operations
bin/rails db:migrate        # Run pending migrations
bin/rails db:rollback       # Rollback last migration
bin/rails db:reset          # Drop, create, migrate, seed

# Console
bin/rails console

# Security checks
bin/brakeman                # Static security analysis
bin/bundler-audit           # Check for vulnerable dependencies

# Code style
bin/rubocop                 # Check Ruby style
```

### Production Build
```bash
# CSS compilation
yarn build:css:compile      # SASS → CSS
yarn build:css:prefix       # Add vendor prefixes
yarn build:css              # Both steps

# Deployment (Docker-based)
bin/kamal deploy
```


## Settings Management System

The **SettingsController** provides a centralized configuration interface with tabbed navigation:

### Tab Structure
- **생산관리 (Production)**: Gijeongddeok defaults, field ordering
- **재고관리 (Inventory)**: Item categories, storage locations, shipment purposes/requesters
- **레시피관리 (Recipe)**: Recipe processes
- **기기관리 (Equipment)**: Equipment types and modes

### Tab Persistence Pattern
**CRITICAL**: When adding CRUD operations in settings, always include `tab` parameter:

```ruby
# Example from SettingsController
def destroy_item_category
  @item_category = ItemCategory.find(params[:id])
  @item_category.destroy
  redirect_to settings_system_path(tab: 'inventory'), notice: '품목 카테고리가 삭제되었습니다.'
end
```

JavaScript automatically reads `?tab=` from URL and activates the correct tab on page load.

### Scroll Position Preservation
Settings page uses SessionStorage to maintain scroll position:
```javascript
// On form submit
sessionStorage.setItem('settingsScrollPosition', window.scrollY);

// On page load
const savedScrollPosition = sessionStorage.getItem('settingsScrollPosition');
if (savedScrollPosition) {
  window.scrollTo(0, parseInt(savedScrollPosition));
  sessionStorage.removeItem('settingsScrollPosition');
}
```

## Special Conventions & Patterns

### 1. Nested Attributes Pattern
Many models use `accepts_nested_attributes_for` for complex forms:
```ruby
# Example from Recipe model
accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true
accepts_nested_attributes_for :recipe_equipments, allow_destroy: true

# Example from FinishedProduct model
accepts_nested_attributes_for :finished_product_recipes, allow_destroy: true
```

This enables creation/update/deletion of associated records in a single form submission.

### 2. Position-based Ordering
Models with drag & drop support use `position` column:
```ruby
# Association with default ordering
has_many :recipe_ingredients, -> { order(position: :asc) }, dependent: :destroy

# Updating positions via AJAX
# Example: PATCH /settings/purposes/update_positions
params[:positions].each_with_index do |id, index|
  ShipmentPurpose.unscoped.find(id).update_column(:position, index + 1)
end
```

### 3. Automatic Version Tracking
Recipe model automatically creates version snapshots before updates:
```ruby
before_update :create_version_snapshot

# Detects changes in:
# - Basic attributes (name, description, notes)
# - Nested ingredients (changed, new, destroyed)
# - Nested equipments (changed, new, destroyed)

# Creates RecipeVersion with:
# - Incremented version number
# - Change summary (list of what changed)
# - Complete JSON snapshot of recipe data
```

### 4. Row Type Pattern
Flexible table structures using `row_type` column:
```ruby
# RecipeIngredient
row_type: 'ingredient' | 'subtotal'
source_type: 'item' | 'ingredient'  # Added 2025-11-18

# IngredientItem
row_type: 'item' | 'ingredient' | 'subtotal'
source_type: distinguishes data source
```

This allows mixing different types of rows in a single table for flexible UI.

**CRITICAL for Recipe Forms**: When rendering forms, check `row_type` to conditionally render subtotal rows vs ingredient rows:
```erb
<% if ingredient_fields.object.row_type == 'subtotal' %>
  <!-- Render subtotal row -->
<% else %>
  <!-- Render ingredient input row -->
<% end %>
```

### 5. Unit Conversion System
**CRITICAL**: Ingredient forms automatically convert all units to grams for totals:

```javascript
function convertToGrams(quantity, unit) {
  const qty = parseFloat(quantity) || 0;

  switch(unit) {
    case 'Kg': return qty * 1000;
    case 'g': return qty;
    case 'L': return qty * 1000;  // Assumes water density
    case 'mL': return qty;         // Assumes water density
    case '개': return 0;            // Cannot convert
    default: return qty;
  }
}
```

This ensures accurate totals when mixing different units (e.g., 1 Kg + 3 L = 4000 g).

**Frontend Requirements:**
- Numeric inputs use `.quantity-input` class with `text-align: right`
- Total displays always show "g" unit
- Subtotals also converted to grams
- Listen to both `input` (quantity change) and `change` (unit change) events

### 6. Stock Calculation Pattern
Calculated fields instead of stored values:
```ruby
# Item model
def total_receipts
  receipts.sum(:quantity)
end

def total_shipments
  shipments.sum(:quantity)
end

def current_stock
  total_receipts - total_shipments
end

def stock_status
  return :critical if minimum_stock.present? && current_stock < minimum_stock
  return :low if optimal_stock.present? && current_stock < optimal_stock
  :sufficient
end
```

### 7. Cascade Delete Protection
Items cannot be deleted if they have receipts or shipments:
```ruby
has_many :receipts, dependent: :restrict_with_error
has_many :shipments, dependent: :restrict_with_error
```

This prevents accidental data loss and maintains referential integrity.

### 8. Auto-generated Codes
Items automatically generate unique codes:
```ruby
before_validation :generate_item_code, on: :create

def generate_item_code
  return if item_code.present?

  last_item = Item.order(:item_code).last
  if last_item && last_item.item_code =~ /ITEM-(\d+)/
    next_number = $1.to_i + 1
  else
    next_number = 1
  end

  self.item_code = "ITEM-#{next_number.to_s.rjust(4, '0')}"
end
```

### 9. Bootstrap Form Validation Override
**CRITICAL**: Bootstrap validation icons (checkmarks/X marks) are globally disabled:
```scss
// app/assets/stylesheets/application.bootstrap.scss
.form-select.is-valid,
.form-select.is-invalid,
.form-select {
  background-image: none !important;
}
```

This prevents unwanted checkmarks from appearing in dropdowns when forms are validated. The global CSS override was added 2025-11-18.

### 10. Recipe Ingredient Source Selection
Recipes can use both Items (품목) and Ingredients (재료) as sources:
```ruby
# RecipeIngredient model
belongs_to :item, optional: true
belongs_to :referenced_ingredient, class_name: 'Ingredient', foreign_key: 'referenced_ingredient_id', optional: true

def display_name
  case source_type
  when 'item'
    item&.name || '품목'
  when 'ingredient'
    referenced_ingredient&.name || '재료'
  else
    item&.name || '품목'
  end
end
```

This pattern allows recipes to reference both raw materials and pre-made ingredient compositions.

### 11. Gijeongddeok (기정떡) Special Handling
The system has special default value management for Gijeongddeok production logs:
- **GijeongddeokDefault**: Singleton model (`first_or_create!`) stores default values for production log fields
- **GijeongddeokFieldOrder**: Manages field display order and metadata (label, category, position)
- Settings page allows drag-and-drop reordering and default value configuration
- Field order is persisted via AJAX to maintain user preferences

### 12. Production Plan Auto-Update
**CRITICAL**: Production logs automatically update related production plan quantities:
```ruby
# In Production::LogsController
def create
  @production_log = ProductionLog.new(production_log_params)
  if @production_log.save
    update_production_plan_quantity(@production_log)  # Auto-update plan
    # ... other processing
  end
end

def update_production_plan_quantity(production_log)
  return unless production_log.production_plan_id.present? && production_log.dough_count.present?

  production_plan = ProductionPlan.find(production_log.production_plan_id)
  production_plan.update(quantity: production_log.dough_count)
end
```

**Behavior**: When a production log is created or updated with a `dough_count` that differs from the associated production plan's `quantity`, the production plan automatically updates to match the actual production amount.

**Example**:
- Production plan has 2.5 units planned
- User creates production log with 3 units actual production
- Production plan quantity automatically updates to 3 units

## Configuration Notes

### Time Zone
```ruby
# config/application.rb
config.time_zone = "Seoul"
config.active_record.default_timezone = :local
```

All timestamps are in Seoul time zone (KST).

### Database
- **Development/Test**: Single SQLite database in `storage/`
- **Production**: Multi-database setup
  - Primary: `storage/production.sqlite3`
  - Cache: `storage/production_cache.sqlite3`
  - Queue: `storage/production_queue.sqlite3`
  - Cable: `storage/production_cable.sqlite3`

### Asset Pipeline
- **CSS**: SCSS → SASS compiler → PostCSS → Autoprefixer → `app/assets/builds/application.css`
- **JavaScript**: ES modules via Import Maps (no bundling required)
- **Watching**: nodemon watches `app/assets/stylesheets/` and triggers rebuild

## Testing Structure

```
test/
├── controllers/         # Controller tests
├── models/             # Model tests
├── integration/        # Integration tests
├── system/            # System tests (Capybara + Selenium)
├── fixtures/          # Test fixtures (YAML)
├── helpers/           # Helper tests
└── mailers/           # Mailer tests
```

**Running tests**:
```bash
bin/rails test                    # All tests
bin/rails test test/models        # Specific directory
bin/rails test:system            # Browser-based system tests
```

## Recent Development History

### 2025-11-19: Production Log Restructuring & Auto-sync
- **Production Logs UI Overhaul**:
  - Changed from daily form view to list-based table view showing all production logs
  - Added dedicated "반죽일지 추가" button that loads production plans as tabs
  - Date navigation (+/- buttons) in new log form to switch between dates
  - Production plans for selected date automatically loaded in tab interface
- **Production Plan Auto-sync**:
  - Production log quantity changes automatically update associated production plan
  - Bidirectional synchronization between logs and plans
  - Ensures actual production always reflects in planning
- **Calendar Cell Height Fix**: Standardized calendar cell heights to 100px for consistent layout
- **Date Auto-navigation**: Fixed date display bug with automatic redirect to current date using SessionStorage
- **Decimal Quantity Support**: Changed production plan quantity from integer to decimal(10,2)

### 2025-11-18: Recipe Ingredient Source Selection & UI Improvements
- **Recipe Ingredient Selection Enhancement**:
  - Added ability to select both Items (품목) and Ingredients (재료) in recipes
  - Migration: `add_ingredient_reference_to_recipe_ingredients.rb`
  - Added `source_type` and `referenced_ingredient_id` columns
  - Implemented `display_name` method for polymorphic display
- **Global Bootstrap Validation Override**: Disabled form validation icons globally to prevent unwanted checkmarks
- **Button Order Standardization**: All forms now use consistent button order (submit left, cancel right)
- **Production Plan Quantity Validation**: Removed `only_integer` constraint to allow decimal quantities
- **Gijeongddeok Settings UI**:
  - Renamed "생산일지" to "반죽일지" (Production Log → Dough Log)
  - Unified field ordering and default value input into single interface
  - Consistent styling with other settings sections (list-group-item pattern)
- **Equipment List Loading Fix**: Fixed JavaScript equipment dropdown generation in recipe forms
- **Settings Enhancement & Ingredient Management**:
  - Item Categories & Storage Locations: Added configurable item categories and storage locations
  - Settings Tab Navigation: Bootstrap tabs with URL parameter persistence (`?tab=inventory`)
  - Scroll Position Preservation: SessionStorage maintains scroll position during form submissions
  - Unit conversion system: All quantities auto-convert to grams (Kg×1000, L×1000, mL×1)
  - Tab Persistence Pattern: All settings CRUD operations include `tab` parameter

### 2025-11-17: Production Features
- **Gijeongddeok Defaults**: Special handling for 기정떡 product with customizable default values
- **Field Ordering**: Drag-and-drop field ordering for production log forms
- **Production Log Forms**: Enhanced with dynamic field management

### 2025-11-16: Production Planning & Logs
- Added `production_plans` for scheduling production
- Added `production_logs` (반죽일지) for detailed production tracking
- Comprehensive metrics: temperatures, ingredient amounts, dough count
- Linked to finished products for traceability

### 2025-11-15: Major Features
- **Recipe Version Management**: Automatic version tracking with complete JSON snapshots
- **Finished Product Management**: Multi-recipe composition with automatic weight calculations
- **Cascade Delete**: Added `ON DELETE CASCADE` to all recipe foreign keys
- **Recipe Delete Validation**: Prevents deletion if used in finished products
- **Shipment Management**: Added purposes and requesters with position-based ordering

### Key Technical Decisions
1. **Version tracking via JSON**: Complete snapshots ensure historical accuracy
2. **Nested forms**: Enables complex data entry in single page
3. **Position management**: Client-side drag & drop + server-side persistence
4. **Calculated stock**: Real-time calculations prevent sync issues
5. **Korean UI**: All user-facing text in Korean
6. **Unit standardization**: All weight/volume units convert to grams for accurate totals
7. **Tab state preservation**: URL parameters + SessionStorage maintain UI state across page reloads

## Common Tasks for Future Development

### Adding a New Model
```bash
# 1. Generate migration
bin/rails g migration CreateModelName field:type field:type

# 2. Create model file
# app/models/model_name.rb
class ModelName < ApplicationRecord
  validates :field, presence: true
  belongs_to :parent
  has_many :children
end

# 3. Run migration
bin/rails db:migrate

# 4. Create controller
# app/controllers/model_names_controller.rb

# 5. Add routes
# config/routes.rb
resources :model_names

# 6. Create views
# app/views/model_names/index.html.erb
# app/views/model_names/show.html.erb
# app/views/model_names/_form.html.erb

# 7. Update navigation
# app/views/layouts/application.html.erb
```

### Adding a New Feature Module
```ruby
# 1. Add namespace in routes
namespace :module_name do
  resources :items
  resources :reports
end

# 2. Create controller directory
# app/controllers/module_name/

# 3. Create views directory
# app/views/module_name/

# 4. Add navigation link
# app/views/layouts/application.html.erb
<li class="nav-item dropdown">
  <a class="nav-link dropdown-toggle" ...>모듈명</a>
  <ul class="dropdown-menu">
    <li><%= link_to module_name_items_path, class: "dropdown-item" do %>
      <i class="bi bi-icon me-2"></i>메뉴명
    <% end %></li>
  </ul>
</li>
```

### Modifying Recipe System
⚠️ **IMPORTANT**: Recipe changes trigger version snapshots

When modifying recipe-related code:
1. Test version creation carefully
2. Verify `before_update` callback logic
3. Ensure JSON serialization includes all needed data
4. Check that `changed?`, `new_record?`, `marked_for_destruction?` work correctly
5. Test with nested attributes

Example testing in console:
```ruby
recipe = Recipe.first
recipe.name = "New Name"
recipe.save  # Should create a version

recipe.recipe_ingredients.first.weight = 100
recipe.save  # Should detect nested change and create version
```

### Database Migrations
Best practices:
```ruby
# Adding foreign key with cascade
add_foreign_key :table_name, :parent_table, on_delete: :cascade

# Modifying existing foreign key (need to drop and recreate)
remove_foreign_key :table_name, :parent_table
add_foreign_key :table_name, :parent_table, on_delete: :cascade

# Adding position column
add_column :table_name, :position, :integer, default: 0
add_index :table_name, :position

# Always test rollback
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:migrate
```


## Security Considerations

- CSRF Protection: Enabled globally via csrf_meta_tags in layout
- Content Security Policy: Configured via csp_meta_tag
- Brakeman: Static security analysis scanner for Rails vulnerabilities
- Bundler Audit: Checks for vulnerable gem dependencies
- No Authentication: Currently no user authentication system (consider adding)
- No Authorization: No role-based access control
- SQLite: Not recommended for high-concurrency production

## Performance Notes

Current Optimizations:
- Solid Cache for caching (SQLite-backed)
- Solid Queue for background jobs
- Eager loading in associations where needed
- Index on frequently queried columns

Performance Considerations:
- Stock calculations are runtime (consider caching for large datasets)
- No pagination currently implemented
- Recipe version snapshots use JSON
- Multiple database queries in stock calculation

## Known Limitations & Future Improvements

Planned Features:
- Automatic inventory deduction from production logs
- Recipe cost calculation
- Equipment utilization statistics
- Enhanced dashboard with charts and KPIs
- User authentication and authorization
- API endpoints for mobile app integration
- Pagination for large datasets
- Inventory alerts and notifications
- Barcode printing
- Production scheduling
- Equipment maintenance tracking
- Export to Excel/PDF

## Important Files for Context

Documentation:
- CLAUDE.md - Comprehensive architecture guide
- CHANGELOG.md - Development history
- INTERACTION_GUIDE.md - Frontend patterns
- README.md - Basic project info

Configuration:
- config/routes.rb - Application structure
- config/database.yml - Database configuration
- db/schema.rb - Database structure
- Gemfile / package.json - Dependencies

Key Models:
- app/models/recipe.rb - Version tracking example
- app/models/item.rb - Auto-code generation, stock calculations
- app/models/finished_product.rb - Multi-recipe composition

Frontend:
- app/javascript/interactions.js - Global helpers
- app/assets/stylesheets/application.bootstrap.scss - Design system
- app/views/layouts/application.html.erb - Main layout

## Quick Reference

Common Commands:
- bin/dev - Start development
- bin/rails console - Rails console
- bin/rails db:migrate - Run migrations
- yarn build:css - Build CSS manually
- tail -f log/development.log - Watch logs

Common Models:
- Item - Inventory items
- Receipt - Receiving inventory
- Shipment - Shipping inventory
- Recipe - Recipes
- FinishedProduct - Final products
- ProductionPlan - Production schedule
- ProductionLog - Production records
- Equipment - Equipment/machinery

Common Paths:
- / - Home dashboard
- /inventory/items - Item management
- /inventory/receipts - Receiving records
- /inventory/shipments - Shipping records
- /recipes - Recipe management
- /finished_products - Finished product management
- /production/plans - Production planning
- /production/logs - Production logs

## UI/UX Consistency Patterns

### Form Button Order
**All forms must follow this order** (left to right):
1. Submit button (등록/수정) - Primary action
2. Cancel button (취소) - Secondary action

Example:
```erb
<div class="d-flex justify-content-end gap-2">
  <%= form.submit "등록", class: "btn-apple btn-apple-primary" %>
  <%= link_to "취소", back_path, class: "btn btn-outline-secondary" %>
</div>
```

### Settings Page List Items
All sortable lists in settings follow this pattern:
```erb
<div class="list-group-item d-flex justify-content-between align-items-center sortable-item"
     data-id="<%= item.id %>"
     style="border: 1px solid #e8e8ed; border-radius: 8px; margin-bottom: 8px; cursor: move;">
  <div class="d-flex align-items-center">
    <i class="bi bi-grip-vertical me-2 text-muted"></i>
    <span style="font-weight: 500;"><%= item.name %></span>
  </div>
  <!-- Right side: input field or delete button -->
</div>
```

This ensures visual consistency across all settings sections (item categories, storage locations, gijeongddeok defaults, etc.).

### Dynamic Row Generation
When adding rows dynamically (e.g., recipe ingredients, equipment), ensure:
1. Event delegation for change handlers (not direct event listeners)
2. JSON data generation in Ruby template, consumed by JavaScript
3. Proper escaping of quotes in HTML template strings
4. Consistent naming: use direct HTML `<select>` tags instead of Rails helpers when needed to avoid validation icons

Example pattern:
```javascript
const itemsData = <%= @items.map { |item| { id: item.id, name: item.name } }.to_json.html_safe %>;
const itemOptions = itemsData.map(item => `<option value="${item.id}">${item.name}</option>`).join('');
```

---

Document Version: 1.3
Last Updated: 2025-11-19
Schema Version: 20251118154716
Rails Version: 8.1.1
Ruby Version: 3.4.7
Node Version: 24.11.1

Created for: Future Claude instances to quickly understand and work with this codebase
