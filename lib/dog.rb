require 'pry'

class Dog

    attr_accessor :name, :breed, :id

    def initialize(id: id, name: name, breed: breed)
        @id = id
        @name = name
        @breed = breed
    end

    def self.create_table
        sql = <<-SQL
            CREATE TABLE IF NOT EXISTS dogs (
                id INTEGER PRIMARY KEY, 
                name TEXT, 
                breed TEXT
            )
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        DB[:conn].execute('DROP TABLE IF EXISTS dogs')
    end

    def save
        dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", self.name, self.breed)
        if dog.empty?
            ins_db(self.name, self.breed)
        else 
            dog.update
        end
        return self
    end

    def ins_db(name, breed)
        sql = <<-SQL
            INSERT INTO dogs (name, breed)
            VALUES (?, ?)
        SQL
        DB[:conn].execute(sql, name, breed)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
    end

    def update
        sql = <<-SQL
          UPDATE dogs SET name = ?, breed = ? WHERE id = ?
        SQL
        
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end
    
    def self.create(name:, breed:)

        new_dog = Dog.new(id: nil, name: name, breed: breed)
        new_dog.save
        
    end

    def self.new_from_db(row)
        new_dog = self.new
        new_dog.id = row[0]
        new_dog.name = row[1]
        new_dog.breed = row[2]
        new_dog
    end

    def self.find_by_id(id)
        sql = "SELECT * FROM dogs WHERE id = ?"
        result = DB[:conn].execute(sql, id)[0]
        Dog.new(id: id, name: result[1], breed: result[2])
    
   end

   def self.find_or_create_by(name:, breed:)
	    dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", name, breed)
	    if !dog.empty?
	      dog_data = dog[0]
	      dog = Dog.new(id: dog_data[0], name: dog_data[1], breed: dog_data[2])
	    else
	      dog = Dog.create(name: name, breed: breed)
	    end
	    return dog
   end

   def self.find_by_name(name)
	    sql = <<-SQL
	      SELECT *
	      FROM dogs
	      WHERE name = ?
	      LIMIT 1
	    SQL
	 
	    DB[:conn].execute(sql, name).map do |row|
	      self.new_from_db(row)
	    end.first
    end
end
