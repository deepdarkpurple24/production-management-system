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

## Deployment Environment (배포 환경)

⚠️ **IMPORTANT**: 이 프로젝트는 다음과 같은 환경에서 운영됩니다:

- **Production Server**: 별도의 Ubuntu 서버 (현재 개발 PC와 다른 컴퓨터)
- **Container**: Docker (docker-compose)
- **Reverse Proxy / CDN**: Cloudflare Tunnel
- **Database**: PostgreSQL 17 (Docker container)
- **Backup**: Supabase (일일 자동 백업, 3 AM KST)

**개발 환경 (현재 PC - Windows)**:
- 이 폴더는 개발용이며, 코드 수정 후 git push하면 서버에서 pull하여 배포
- 서버 배포 명령어는 서버에서 직접 실행해야 함
- CSS 빌드는 로컬에서 `yarn build:css` 후 커밋

**서버 배포 절차** (Ubuntu 서버에서 실행):
```bash
cd ~/production-management-system
git pull
docker-compose down
docker-compose up -d --build
```

## Technology Stack

### Backend
- **Framework**: Ruby on Rails 8.1.1
- **Ruby Version**: 3.4.7
- **Database**: PostgreSQL 17 (production), SQLite3 (development/test)
- **Authentication**: Devise (email/password with device-based access control)
- **Authorization**: Pundit (role-based policies)
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
│   ├── services/             # Business logic services
│   │   ├── ingredient_inventory_service.rb  # FIFO inventory management
│   │   └── production_log_initializer.rb    # Auto-create production logs
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

- **OpenedItem** (`opened_items`): 개봉품 관리
  - Tracks partially used inventory items with remaining weight
  - FIFO (First-In-First-Out) based on expiration dates
  - Links to receipt and item
  - Scopes: `available` (remaining_weight > 0), `by_expiration` (sorted by expiration date)
  - Methods: `deduct_weight`, `restore_weight`, `depleted?`

- **CheckedIngredient** (`checked_ingredients`): 체크된 재료
  - Records ingredient usage in production logs
  - Stores used_weight, expiration_date, receipt_id, opened_item_id
  - Links production log to inventory consumption
  - Part of automatic inventory deduction system

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

### 7. Authentication & Authorization (인증/권한 관리)
- **User** (`users`): 사용자 (Devise)
  - Email/password authentication
  - Trackable: sign_in_count, current/last sign_in timestamps and IPs
  - Custom fields: `admin` (boolean), `name` (string)
  - First registered user automatically becomes admin
  - Device authorization methods: `device_authorized?`, `authorize_device`, `revoke_device`

- **AuthorizedDevice** (`authorized_devices`): 승인된 디바이스
  - Browser-based device fingerprinting (SHA-256 hashed)
  - Stores: fingerprint, device_name, browser, os, active status
  - Tracks last_used_at timestamp
  - Scopes: `active`, `inactive`, `recent`
  - Methods: `update_last_used!`, `deactivate!`, `display_name`

- **LoginHistory** (`login_histories`): 로그인 이력
  - Tracks ALL login attempts (successful and failed)
  - Records: user, fingerprint, ip_address, browser, os, device_name, success, failure_reason, attempted_at
  - Scopes: `successful`, `failed`, `recent`, `today`, `this_week`, `by_ip`
  - Class method: `log_attempt` for creating records
  - Methods: `display_status`, `status_color`

**Device Fingerprinting**: Browser-based unique identification using:
- Canvas fingerprinting (text rendering variations)
- WebGL renderer information (GPU vendor/model)
- Available fonts detection
- Screen resolution and pixel ratio
- Timezone and language settings
- Hardware concurrency (CPU cores)
- Touch support detection
- SHA-256 hashing for security

**Authentication Flow**:
1. **Registration**: Auto-authorize the device used for signup (first user becomes admin)
2. **Login**: Check device fingerprint against authorized_devices, reject if not authorized
3. **Device Management**: Admins can manually authorize/revoke devices for users
4. **Login History**: All attempts logged with success/failure reasons


## Key Routes & Endpoints

### Authentication (Devise)
```ruby
devise_for :users, controllers: {
  sessions: 'users/sessions',          # Custom login with device check
  registrations: 'users/registrations' # Custom registration (admin-only after first user)
}

# Routes:
GET    /users/sign_in          # Login page
POST   /users/sign_in          # Login action (with device fingerprint check)
DELETE /users/sign_out         # Logout
GET    /users/sign_up          # Registration page (blocked unless admin or first user)
POST   /users                  # Registration action (auto-authorize device)
```

### Admin Module
```ruby
namespace :admin do
  resources :users do
    resources :authorized_devices, only: [:create, :destroy] do
      member do
        patch :toggle_active  # Activate/deactivate device
      end
    end
  end
  resources :login_histories, only: [:index]  # Security monitoring dashboard
end

# Routes:
GET    /admin/users                                      # User list
GET    /admin/users/:id                                  # User detail (devices + login history)
GET    /admin/users/:id/edit                             # Edit user
PATCH  /admin/users/:id                                  # Update user
DELETE /admin/users/:id                                  # Delete user (restrictions apply)
POST   /admin/users/:user_id/authorized_devices          # Manually authorize device
DELETE /admin/users/:user_id/authorized_devices/:id      # Delete device
PATCH  /admin/users/:user_id/authorized_devices/:id/toggle_active  # Toggle device active status
GET    /admin/login_histories                            # Login history (all users)
```

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
  resources :opened_items, only: [:index]  # 개봉품 관리
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

#### Recommended: Automated Setup
```bash
# One command to set up everything!
bin/setup

# Automatically handles:
# - Dependency installation (bundle, yarn)
# - Database creation and migration
# - CSS building
# - Git hooks installation (for auto-sync on pull)
# - Server start
```

#### Manual Setup (if needed)
```bash
# Install dependencies
bundle install
yarn install

# Database setup
bin/rails db:create db:migrate db:seed

# Build CSS
yarn build:css

# Install Git hooks (recommended)
bin/install-hooks

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

# Authentication management (via console)
bin/rails console
> User.first                                    # Check first user (should be admin)
> user = User.find_by(email: 'user@example.com')
> user.update(admin: true)                      # Make user admin
> user.authorized_devices                       # List user's devices
> user.authorize_device(fingerprint, device_info)  # Manually authorize device
> user.revoke_device(fingerprint)               # Revoke device
> LoginHistory.recent.limit(10)                 # Recent login attempts

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

### Post-Pull Environment Sync

**CRITICAL**: After pulling changes from remote repository, always run these checks to ensure proper environment sync:

#### Fully Automated (Recommended) 🎯

Install Git hooks once to automate everything:

```bash
# One-time setup: Install Git hooks
bin/install-hooks
```

After installation, **git pull automatically triggers environment sync**:
- ✅ Detects and runs pending migrations
- ✅ Updates dependencies if Gemfile/package.json changed
- ✅ Rebuilds CSS if SCSS files changed
- ✅ Shows summary and server restart reminder

**Usage after hook installation:**
```bash
git pull  # Everything happens automatically!
# Then restart server: bin/dev
```

#### Semi-Automatic (Manual trigger)
```bash
# Run this script after git pull to sync everything
bin/setup-after-pull
```

#### Manual Steps (if script not available)
```bash
# 1. Check for pending migrations
bin/rails db:migrate:status | grep "down"

# 2. Run pending migrations if any
bin/rails db:migrate

# 3. Update dependencies
bundle install
yarn install

# 4. Rebuild CSS (critical if SCSS files changed)
yarn build:css

# 5. Restart server
# Ctrl+C to stop, then:
bin/dev
```

#### Common Issues After Pull

**Problem**: UI changes not visible
- **Cause**: CSS not rebuilt
- **Solution**: `yarn build:css` then refresh browser with hard reload (Ctrl+Shift+R)

**Problem**: Database errors (column not found, type mismatch)
- **Cause**: Migrations not run
- **Solution**: `bin/rails db:migrate`
- **Check**: `bin/rails db:migrate:status` should show all migrations as "up"

**Problem**: Missing dependencies
- **Cause**: Gemfile or package.json changed
- **Solution**: `bundle install && yarn install`

**Problem**: Server behaving unexpectedly
- **Cause**: Server not restarted after changes
- **Solution**: Restart server (Ctrl+C then `bin/dev`)

#### Quick Verification
```bash
# Verify everything is synced
git log -1 --oneline                    # Check current commit
bin/rails db:migrate:status | tail -5  # Check migration status
ls -lh app/assets/builds/application.css # Check CSS build timestamp
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

### 13. Device-Based Authentication Pattern
**CRITICAL**: All Devise forms must include device fingerprint hidden fields for authentication to work.

**Form Selector Pattern** (`device_fingerprint.js`):
```javascript
// MUST include all possible form action paths
const deviseForms = document.querySelectorAll(
  'form[action*="sign_in"], form[action*="sign_up"], form[action="/users"], form[action*="/admin/users"]'
);
```

**Why Multiple Selectors**:
- `form[action*="sign_in"]` - Login form (`/users/sign_in`)
- `form[action*="sign_up"]` - May not match due to exact path
- `form[action="/users"]` - Registration form (exact path)
- `form[action*="/admin/users"]` - Admin user creation

**Hidden Fields Injected**:
```javascript
// Four hidden fields added to each form
fingerprintField.name = 'device_fingerprint';     // SHA-256 hash
browserField.name = 'device_browser';             // Chrome, Firefox, etc.
osField.name = 'device_os';                       // Windows, macOS, Linux
deviceNameField.name = 'device_name';             // "Chrome on Windows"
```

**Controller Pattern**:
```ruby
# In SessionsController#create or RegistrationsController#create
fingerprint = params[:device_fingerprint]
device_info = {
  browser: params[:device_browser],
  os: params[:device_os],
  device_name: params[:device_name]
}

# Check authorization
unless resource.device_authorized?(fingerprint)
  # Log failed attempt with reason
  LoginHistory.log_attempt(user: resource, fingerprint: fingerprint,
                           ip: request.remote_ip, success: false,
                           failure_reason: "디바이스가 승인되지 않았습니다", **device_info)
  # Reject login
end
```

**First User Flow**:
```ruby
# RegistrationsController#create
if User.count.zero?
  resource.admin = true  # First user becomes admin
end

if resource.persisted?
  resource.authorize_device(fingerprint, device_info)  # Auto-authorize
  LoginHistory.log_attempt(...)  # Log successful registration
end
```

### 14. FIFO Inventory Management System
**CRITICAL**: Ingredient checking in production logs triggers automatic inventory deduction using FIFO (First-In-First-Out) logic.

**Workflow** (`IngredientInventoryService`):
1. **Find Item**: Get item from RecipeIngredient
2. **FIFO Selection**: Query receipts ordered by `expiration_date ASC, receipt_date ASC`
3. **Find/Create OpenedItem**:
   - Check existing opened items with sufficient remaining_weight
   - If none found, open new receipt (creates OpenedItem with unit_weight as remaining_weight)
4. **Deduct Weight**: Call `opened_item.deduct_weight(used_weight)`
5. **Create CheckedIngredient**: Record with used_weight, expiration_date, receipt_id, opened_item_id
6. **Auto Shipment**: If `opened_item.depleted?`, create Shipment with purpose "생산 사용"

**Uncheck Behavior**:
- Restore weight to OpenedItem only (shipment remains intact - item already opened)
- Delete CheckedIngredient record

**Service Pattern**:
```ruby
# Controller calls service
result = IngredientInventoryService.check_ingredient(
  production_log, recipe_ingredient, batch_index, used_weight
)

if result[:success]
  checked_ingredient = result[:checked_ingredient]
  # Display expiration_date in UI
else
  # Show errors: result[:errors]
end
```

**Key Requirements**:
- Receipts MUST have `expiration_date` to be used in FIFO
- OpenedItem tracks `remaining_weight` (initially = receipt.unit_weight)
- Unit conversion handled by `convert_to_grams(weight, unit)`
- Expiration dates displayed in production log tables as `yy.mm.dd`

**Table Structure**:
```
Production Log Ingredient Table:
| Recipe Name + Datetime | Weight  | Expiration Date |
|------------------------|---------|-----------------|
| 재료명                  | 1000g   | 25.11.29        |
```

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
- **Production**: PostgreSQL with multi-database setup
  - Primary: `production_management_system_production`
  - Cache: `production_management_system_cache`
  - Queue: `production_management_system_queue`
  - Cable: `production_management_system_cable`
  - Deployment: Docker Compose with PostgreSQL 17 Alpine
  - Backup: Automated daily backup to Supabase (3 AM KST via cron)

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

### 2025-11-27: PostgreSQL Migration & Supabase Backup System
- **Database Migration**: SQLite → PostgreSQL
  - Migrated from SQLite to PostgreSQL for production scalability
  - Created comprehensive migration rake task (`lib/tasks/migrate_sqlite_to_postgresql.rake`)
  - Preserves all record IDs and resets PostgreSQL sequences
  - Handles 35 models in dependency order (109 records migrated successfully)
- **Docker Compose Deployment**:
  - PostgreSQL 17 Alpine container (`docker-compose.yml`)
  - Volume persistence: `postgres_data`
  - Health checks configured
  - Environment variables: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- **Supabase Backup System**:
  - Dual backup scripts: Original (`backup_to_supabase.sh`) and Simplified (`backup_to_supabase_simple.sh`)
  - Simplified version backs up to default `postgres` database for dashboard visibility
  - Automated daily backups via cron (3 AM KST)
  - Backup retention: 7 days
  - Restore script available (`restore_from_supabase.sh`)
  - Connection: Supabase Connection Pooler (Session Mode, port 5432) for compatibility
  - Logs: `~/logs/pg_backup_cron.log`
- **Backup Commands**:
  ```bash
  # Manual backup
  ./scripts/backup_to_supabase_simple.sh

  # Restore from Supabase (disaster recovery)
  ./scripts/restore_from_supabase.sh

  # Check cron status
  crontab -l

  # View backup logs
  tail -f ~/logs/pg_backup_cron.log
  ```
- **Environment Setup**:
  - Requires `SUPABASE_PASSWORD` environment variable
  - PostgreSQL client tools (`psql`, `pg_dump`) required on server
  - `.gitignore` updated to exclude `docker-compose.yml`, `*.sql`, `*.sql.gz`
- **Security**:
  - Supabase credentials stored in environment variables only
  - No hardcoded passwords in scripts
  - Backup files compressed with gzip
  - GitGuardian false positive addressed (environment variable usage is correct)

### 2025-11-23: Authentication & Authorization System
- **Devise Integration**:
  - Added Devise gem for user authentication
  - Enabled trackable module for login monitoring (sign_in_count, timestamps, IPs)
  - Custom fields: `admin` (boolean), `name` (string)
  - First registered user automatically becomes admin
- **Device-Based Access Control**:
  - Browser fingerprinting using Canvas, WebGL, fonts, screen, hardware, timezone
  - SHA-256 hashing of device signatures for security
  - AuthorizedDevice model tracks fingerprint, browser, os, device_name, active status
  - Device authorization required for login (admins can manually authorize/revoke)
  - SessionStorage caching of fingerprint (cleared on browser close)
- **Login History & Security Monitoring**:
  - LoginHistory model tracks ALL login attempts (success and failed)
  - Records: user, fingerprint, ip_address, browser, os, failure_reason, attempted_at
  - Scopes for filtering: successful, failed, recent, today, this_week, by_ip
  - Complete audit trail for security compliance
- **Custom Devise Controllers**:
  - SessionsController: Device fingerprint validation before login
  - RegistrationsController: Auto-authorize device on signup, admin-only registration after first user
  - Login flow: authenticate → check device → log attempt → update device timestamp
- **Admin Interface**:
  - User management: list, create, edit, delete (with protections)
  - Device management: view, authorize, revoke, toggle active status
  - Login history dashboard with statistics and filtering
  - Apple-refined design consistent with application theme
- **JavaScript Device Fingerprinting** (`device_fingerprint.js`):
  - DeviceFingerprint class with async generation
  - Multiple fingerprinting signals combined into unique hash
  - Auto-injects hidden fields into Devise forms (sign_in, sign_up, admin user creation)
  - Browser and OS detection for display purposes
- **Security Features**:
  - CSRF protection (existing)
  - Device-based access control (new)
  - Login attempt tracking (new)
  - Admin action restrictions (cannot delete self or last admin)
  - Flash messages for authentication failures with specific reasons
- **Database Migrations**:
  - `devise_create_users`: Users table with Devise fields + custom admin/name
  - `create_authorized_devices`: Device authorization tracking
  - `create_login_histories`: Login attempt audit trail
- **Routes Updates**:
  - `devise_for :users` with custom controllers
  - Admin namespace for users, authorized_devices, login_histories
  - Device toggle/delete actions
- **ApplicationController Update**:
  - Added `before_action :authenticate_user!` to enforce authentication globally
  - All pages now require login
- **Navigation Updates** (`application.html.erb`):
  - Added admin dropdown menu (visible only to admins)
  - Login/logout links
  - Flash message display area
- **Critical Bug Fix**:
  - JavaScript form selector didn't match registration form path `/users`
  - Updated selector to include `form[action="/users"]` and `form[action*="/admin/users"]`
  - Fixed issue where device fingerprint wasn't added to signup form

### 2025-11-23: FIFO Inventory Management System
- **Automatic Inventory Deduction**:
  - Ingredient checking in production logs now triggers automatic inventory management
  - FIFO (First-In-First-Out) based on expiration dates
  - OpenedItem model tracks partially used inventory with remaining weight
  - CheckedIngredient model records ingredient usage with expiration date tracking
- **IngredientInventoryService**:
  - Core business logic for FIFO inventory selection and deduction
  - Automatic shipment creation when items depleted (purpose: "생산 사용")
  - Uncheck restores weight to opened items but keeps shipment intact
  - Comprehensive error handling and logging
- **ProductionLogInitializer Service**:
  - Auto-creates production logs when production plans created
  - Pre-calculates ingredient_weights based on batch count and equipment capacity
  - Eliminates need for on-demand log creation during first ingredient check
- **Opened Items Management Page**:
  - New route: `/inventory/opened_items`
  - Displays all opened items with remaining weight
  - Shows expiration dates with color-coded D-day indicators (red/orange/yellow/green)
  - Groups by item with summary statistics
- **Production Log UI Improvements**:
  - Added "중량" and "유통기한" column headers in ingredient tables
  - Recipe name and completion datetime combined in first column
  - Expiration dates display in `yy.mm.dd` format
  - Table structure: Recipe+Time | Weight | Expiration Date
- **Database Migrations**:
  - `create_opened_items`: Tracks opened inventory items with remaining_weight
  - `add_inventory_fields_to_checked_ingredients`: Links checked ingredients to receipts and opened items

### 2025-11-21: Production Log Tab Structure - Recipe-Based Tabs
- **Tab Structure Refactoring**:
  - Changed production log creation from plan-based tabs to recipe-based tabs
  - Multi-recipe finished products (e.g., 백미보름떡) now display separate tabs for each recipe (백미크림, 보름떡)
  - Each recipe gets its own independent form instead of stacking forms vertically
  - Tab ID format: `plan-{plan_id}-recipe-{recipe_id || 'none'}`
  - Tab labels show recipe name directly for better clarity
- **JavaScript Updates**:
  - Updated gijeongddeok default value loading to work with new tab ID structure
  - Fixed field ID generation to use tab_id instead of plan.id
  - Maintained +/- button functionality for dough_count fields
- **Pattern**: When a finished product has multiple recipes, iterate through `plan.finished_product.recipes` to create tab_items array with `{plan: plan, recipe: recipe}` pairs

### 2025-11-20: Version Tracking System Improvements
- **Comprehensive Notes Field Support**:
  - Added `notes` field to `item_versions` table for complete Item version tracking
  - Recipe ingredients now track notes with change detection in version history
  - Finished product recipes track notes per recipe with change highlighting
  - Ingredient items track notes per item with comparison logic
  - All version views display notes with yellow background when changed
- **Version History UI Consistency**:
  - Standardized "new/deleted" indicators across all version views (fixed reversed logic)
  - Added unit change detection for ingredient items and production units
  - Added text field change detection for name, description fields
  - Fixed notes architecture: moved from model-level to item-level where appropriate
- **Item Management UX**:
  - Changed update redirect from detail page to list page for faster workflow
  - Added notes display in item version history with change tracking
- **Version Tracking Pattern**:
  - All models with notes now save to version snapshots
  - Comparison logic highlights changes in yellow (#fff3cd)
  - Deleted items shown in red (#f8d7da), added items in blue (#d1ecf1)
  - Change arrows show before → after values

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

**Implemented Security Measures**:
- **CSRF Protection**: Enabled globally via csrf_meta_tags in layout
- **Content Security Policy**: Configured via csp_meta_tag
- **Authentication**: Devise-based email/password authentication
- **Email Confirmation**: Devise :confirmable module (email verification required)
- **Device-based Access Control**: Browser fingerprinting with SHA-256 hashing
- **Login History Tracking**: Complete audit trail of all login attempts
- **Authorization**: Admin-based role system (first user auto-admin)
- **Rate Limiting**: Rack::Attack for brute force protection
- **Session Timeout**: Devise :timeoutable (30 minutes inactivity)
- **Brakeman**: Static security analysis scanner for Rails vulnerabilities
- **Bundler Audit**: Checks for vulnerable gem dependencies

**Device Fingerprinting Security**:
- SHA-256 hashing of browser-based device signatures
- Multiple fingerprinting signals (Canvas, WebGL, fonts, hardware, etc.)
- SessionStorage for fingerprint caching (cleared on browser close)
- Device authorization required for login (admin can manage)
- Last used timestamp tracking for device activity monitoring

**Authentication Security Features**:
- Trackable module: Monitors sign-in count, timestamps, and IP addresses
- Login history: Success/failure tracking with detailed failure reasons
- Device management: Admins can activate/deactivate devices
- Registration restriction: Only admins can create new users (after first user)
- Auto-authorization: Devices used for registration automatically authorized
- Email confirmation: Users must verify email before login (admin-created users skip this)
- Session timeout: Auto-logout after 30 minutes of inactivity with 5-minute warning

**Rate Limiting Configuration** (Rack::Attack):
- Login attempts: 5 per 20 seconds (by IP and email)
- Registration: 3 per hour (by IP)
- Password reset: 3 per hour (by IP)
- Email confirmation resend: 3 per hour (by IP)
- General requests: 300 per 5 minutes (by IP)
- Localhost automatically whitelisted
- Custom 429 error page in Korean

**Session Timeout Configuration**:
- Timeout period: 30 minutes of inactivity
- Warning: 5 minutes before expiration
- Stimulus controller: session_timeout_controller.js
- Activity detection: mouse, keyboard, scroll, touch events
- User-friendly countdown timer with "Continue" button

**Known Security Limitations**:
- **Device Fingerprinting**: Can be evaded by sophisticated attackers (browser fingerprinting is not foolproof)
- **No Two-Factor Authentication**: Device-based authorization is single-factor
- **Admin Deletion Protection**: Cannot delete last admin or self, but no audit trail for admin actions
- **Backup Security**: Supabase credentials stored in environment variables (secure, but consider additional encryption for backup files)

**Recommended Security Improvements**:
1. Consider adding two-factor authentication (TOTP)
2. Add admin action audit logging
3. Implement IP-based blocking for repeated violations
4. Regular security dependency updates (bundler-audit, brakeman)
5. Consider encrypting backup files with GPG before storing

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
- BACKUP_GUIDE.md - PostgreSQL and Supabase backup procedures
- README.md - Basic project info

Configuration:
- config/routes.rb - Application structure (includes authentication routes)
- config/database.yml - Database configuration (PostgreSQL production, SQLite dev/test)
- config/initializers/devise.rb - Devise authentication configuration (timeout_in, confirmable)
- config/initializers/rack_attack.rb - Rate limiting rules
- config/locales/devise.ko.yml - Korean authentication messages
- config/locales/ko.yml - Korean time/date formats
- config/application.rb - i18n locale settings, Rack::Attack middleware
- db/schema.rb - Database structure
- Gemfile / package.json - Dependencies

Scripts:
- scripts/backup_to_supabase.sh - Original backup script (separate databases)
- scripts/backup_to_supabase_simple.sh - Simplified backup (default postgres DB)
- scripts/restore_from_supabase.sh - Disaster recovery restore script
- lib/tasks/migrate_sqlite_to_postgresql.rake - One-time SQLite to PostgreSQL migration

Key Models:
- app/models/user.rb - Authentication, device authorization methods
- app/models/authorized_device.rb - Device fingerprint tracking
- app/models/login_history.rb - Login attempt audit trail
- app/models/recipe.rb - Version tracking example
- app/models/item.rb - Auto-code generation, stock calculations
- app/models/finished_product.rb - Multi-recipe composition

Controllers:
- app/controllers/application_controller.rb - Global authentication requirement
- app/controllers/users/sessions_controller.rb - Custom login with device check
- app/controllers/users/registrations_controller.rb - Custom registration with auto-device authorization
- app/controllers/admin/users_controller.rb - User management
- app/controllers/admin/authorized_devices_controller.rb - Device management
- app/controllers/admin/login_histories_controller.rb - Login history dashboard

Frontend:
- app/javascript/device_fingerprint.js - Browser fingerprinting for device identification
- app/javascript/controllers/session_timeout_controller.js - Session timeout warning system
- app/javascript/interactions.js - Global helpers
- app/assets/stylesheets/application.bootstrap.scss - Design system
- app/views/layouts/application.html.erb - Main layout (admin menu, flash messages, session timeout)
- app/views/devise/sessions/new.html.erb - Login page
- app/views/devise/mailer/confirmation_instructions.html.erb - Email confirmation template
- app/views/devise/registrations/new.html.erb - Registration page
- app/views/admin/users/index.html.erb - User management interface
- app/views/admin/users/show.html.erb - User detail (devices + login history)
- app/views/admin/login_histories/index.html.erb - Login history dashboard

## Quick Reference

Common Commands:
- bin/dev - Start development
- bin/rails console - Rails console
- bin/rails db:migrate - Run migrations
- yarn build:css - Build CSS manually
- tail -f log/development.log - Watch logs

Common Models:
- User - User accounts (authentication)
- AuthorizedDevice - Device authorization
- LoginHistory - Login attempt tracking
- Item - Inventory items
- Receipt - Receiving inventory
- Shipment - Shipping inventory
- OpenedItem - Opened inventory items
- Recipe - Recipes
- FinishedProduct - Final products
- ProductionPlan - Production schedule
- ProductionLog - Production records
- Equipment - Equipment/machinery

Common Paths:
- /users/sign_in - Login page
- /users/sign_up - Registration (admin-only after first user)
- /admin/users - User management (admin only)
- /admin/users/:id - User detail with devices and login history
- /admin/login_histories - Login history dashboard (admin only)
- / - Home dashboard
- /inventory/items - Item management
- /inventory/receipts - Receiving records
- /inventory/opened_items - Opened items management
- /inventory/shipments - Shipping records
- /inventory/stocks - Stock status
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

Document Version: 1.9
Last Updated: 2025-11-27
Schema Version: 20251126131532
Rails Version: 8.1.1
Ruby Version: 3.4.7
Node Version: 24.11.1
PostgreSQL Version: 17 (Alpine)

Created for: Future Claude instances to quickly understand and work with this codebase

---

## Changelog

### Version 1.9 (2025-11-27)
- **Database Migration**:
  - Migrated from SQLite to PostgreSQL for production
  - Added migration rake task documentation
  - Docker Compose deployment with PostgreSQL 17
- **Backup System**:
  - Supabase automated backup system (daily 3 AM KST)
  - Dual backup scripts (original and simplified)
  - Restore procedures documented
  - Backup commands and monitoring added
- **Documentation**:
  - Added BACKUP_GUIDE.md reference
  - Updated database configuration details
  - Added backup/restore scripts to Important Files
  - Updated security considerations for backup
- **Configuration**:
  - Environment variable management for Supabase
  - .gitignore updates for sensitive files

### Version 1.8 (2025-11-26)
- **Security Enhancements**:
  - Email Confirmation: Added Devise :confirmable module for email verification
  - Rate Limiting: Implemented Rack::Attack for brute force protection
  - Session Timeout: Added Devise :timeoutable with 30-minute inactivity logout
  - Mass Assignment Fix: Secured admin/sub_admin privilege escalation vulnerability
- **Internationalization**:
  - Korean locale (ko) set as default
  - Added config/locales/devise.ko.yml and config/locales/ko.yml
- **Frontend**:
  - Session timeout warning system with countdown timer (Stimulus controller)
  - Activity detection for automatic session renewal
- **Database**:
  - Added confirmation fields to users table (confirmation_token, confirmed_at, etc.)
  - Auto-confirmed existing users during migration
- **Configuration**:
  - config/initializers/rack_attack.rb: Rate limiting rules
  - config/application.rb: i18n settings and Rack::Attack middleware
- Schema updated to 20251126131532 (add_confirmable_to_users)

### Version 1.7 (2025-11-23)
- Added comprehensive Authentication & Authorization System documentation
- Documented Devise integration with device-based access control
- Added User, AuthorizedDevice, LoginHistory models to Core Domain Models
- Added authentication and admin routes documentation
- Added authentication management console commands
- Updated Security Considerations with implemented measures and recommendations
- Added detailed Recent Development History for authentication system
- Updated Common Models and Common Paths to include authentication-related items
- Schema updated to 20251123075852 (create_login_histories)
