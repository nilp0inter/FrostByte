-- FrostByte Seed Data
-- Additional Ingredients with their freezer shelf life in days
INSERT INTO ingredient (name, expire_days, best_before_days) VALUES
    ('marisco', 180, 120),
    ('ternera', 365, 270),
    ('cerdo', 365, 270),
    ('guiso', 365, 300),
    ('postre', 90, 60),
    ('salsa', 365, 300)
ON CONFLICT (name) DO NOTHING;

-- Container types with servings per unit
INSERT INTO container_type (name, servings_per_unit) VALUES
    ('Bolsa de 3 raciones', 3.00),
    ('Bolsa de 1 ración', 1.00),
    ('Bolsa de 2 raciones', 2.00),
    ('Cubo de 250ml', 0.75),
    ('Cubo de 125ml', 0.375),
    ('Tupper de aluminio grande (1100ml)', 3.25),
    ('Tupper de aluminio mediano (980ml)', 3.00),
    ('Tupper de alumino pequeño (300ml)', 0.90),
    ('Tupper de cristal rectangular grande (1800ml)', 5.50),
    ('Tupper de cristal rectangular mediano (1000ml)', 3.00),
    ('Tupper de cristal redondo (400ml)', 1.25),
    ('Tupper de cristal cuadrado grande (1200ml)', 3.50),
    ('Tupper de cristal cuadrado mediano (600ml)', 1.75),
    ('Tupper de cristal cuadrado pequeño (180ml)', 0.50)
ON CONFLICT (name) DO NOTHING;
