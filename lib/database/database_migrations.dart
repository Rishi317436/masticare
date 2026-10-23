class DatabaseMigrations {
  DatabaseMigrations._();

  static const List<String> migrations = [
    '''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      phone TEXT,
      role TEXT,
      location TEXT,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS cattle (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      breed TEXT,
      age INTEGER,
      sex TEXT,
      image_path TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS analyses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cattle_id INTEGER NOT NULL,
      thermal_image_path TEXT,
      prediction TEXT,
      healthy_probability REAL,
      mastitis_probability REAL,
      confidence REAL,
      timestamp TEXT NOT NULL,
      FOREIGN KEY (cattle_id) REFERENCES cattle(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE INDEX IF NOT EXISTS idx_cattle_user_id ON cattle(user_id);
    ''',
    '''
    CREATE INDEX IF NOT EXISTS idx_analyses_cattle_id ON analyses(cattle_id);
    ''',
  ];
}
