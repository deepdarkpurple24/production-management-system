namespace :db do
  desc "Migrate data from SQLite to PostgreSQL"
  task migrate_to_postgres: :environment do
    puts "=" * 80
    puts "SQLite → PostgreSQL 데이터 마이그레이션 시작"
    puts "=" * 80
    puts ""

    # SQLite 연결 설정
    sqlite_config = {
      adapter: 'sqlite3',
      database: Rails.root.join('storage', 'production.sqlite3').to_s
    }

    # 마이그레이션할 모델 순서 (외래 키 관계 고려)
    models = [
      # 1. 독립 모델 (외래 키 없음)
      { model: User, name: 'User' },
      { model: EquipmentType, name: 'EquipmentType' },
      { model: EquipmentMode, name: 'EquipmentMode' },
      { model: RecipeProcess, name: 'RecipeProcess' },
      { model: ItemCategory, name: 'ItemCategory' },
      { model: StorageLocation, name: 'StorageLocation' },
      { model: ShipmentPurpose, name: 'ShipmentPurpose' },
      { model: ShipmentRequester, name: 'ShipmentRequester' },
      { model: GijeongddeokDefault, name: 'GijeongddeokDefault' },
      { model: GijeongddeokFieldOrder, name: 'GijeongddeokFieldOrder' },

      # 2. User 관련
      { model: AuthorizedDevice, name: 'AuthorizedDevice' },
      { model: LoginHistory, name: 'LoginHistory' },

      # 3. 품목 관련
      { model: Item, name: 'Item' },
      { model: Receipt, name: 'Receipt' },
      { model: Shipment, name: 'Shipment' },
      { model: OpenedItem, name: 'OpenedItem' },

      # 4. 장비
      { model: Equipment, name: 'Equipment' },

      # 5. 재료
      { model: Ingredient, name: 'Ingredient' },
      { model: IngredientItem, name: 'IngredientItem' },

      # 6. 레시피
      { model: Recipe, name: 'Recipe' },
      { model: RecipeVersion, name: 'RecipeVersion' },
      { model: RecipeIngredient, name: 'RecipeIngredient' },
      { model: RecipeEquipment, name: 'RecipeEquipment' },

      # 7. 완제품
      { model: FinishedProduct, name: 'FinishedProduct' },
      { model: FinishedProductRecipe, name: 'FinishedProductRecipe' },

      # 8. 생산 계획 및 로그
      { model: ProductionPlan, name: 'ProductionPlan' },
      { model: ProductionLog, name: 'ProductionLog' },
      { model: CheckedIngredient, name: 'CheckedIngredient' }
    ]

    begin
      # SQLite 연결 생성
      puts "📂 SQLite 데이터베이스 연결 중..."
      sqlite_db = ActiveRecord::Base.establish_connection(sqlite_config)

      # 각 모델별로 데이터 복사
      total_records = 0

      models.each do |model_info|
        model = model_info[:model]
        name = model_info[:name]

        print "📋 #{name} 마이그레이션 중..."

        begin
          # SQLite에서 모든 레코드 가져오기
          records = model.all.to_a
          count = records.size

          if count == 0
            puts " ⏭️  건너뜀 (데이터 없음)"
            next
          end

          # PostgreSQL로 전환
          ActiveRecord::Base.establish_connection(:production)

          # 레코드 복사
          success_count = 0
          error_count = 0

          records.each_with_index do |record, index|
            begin
              # 속성 복사 (타임스탬프 포함)
              attrs = record.attributes.except('id')

              # 새 레코드 생성
              new_record = model.new(attrs)
              new_record.id = record.id  # ID 유지
              new_record.save!(validate: false)  # 검증 건너뛰기

              success_count += 1
            rescue => e
              error_count += 1
              puts "\n  ⚠️  레코드 #{index + 1} 실패: #{e.message}"
            end
          end

          # 시퀀스 재설정 (PostgreSQL)
          if success_count > 0
            max_id = model.maximum(:id)
            ActiveRecord::Base.connection.execute(
              "SELECT setval('#{model.table_name}_id_seq', #{max_id})"
            )
          end

          puts " ✅ 완료 (#{success_count}/#{count})"
          total_records += success_count

          # SQLite로 다시 전환 (다음 모델을 위해)
          ActiveRecord::Base.establish_connection(sqlite_config)

        rescue => e
          puts " ❌ 실패: #{e.message}"
        end
      end

      # PostgreSQL로 최종 전환
      ActiveRecord::Base.establish_connection(:production)

      puts ""
      puts "=" * 80
      puts "✅ 마이그레이션 완료!"
      puts "=" * 80
      puts "총 #{total_records}개 레코드 복사됨"
      puts ""

      # 결과 확인
      puts "📊 PostgreSQL 데이터 확인:"
      models.each do |model_info|
        model = model_info[:model]
        name = model_info[:name]
        count = model.count
        puts "  - #{name}: #{count}개" if count > 0
      end

    rescue => e
      puts ""
      puts "❌ 에러 발생: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    ensure
      # 원래 연결로 복원
      ActiveRecord::Base.establish_connection(:production)
    end
  end
end
