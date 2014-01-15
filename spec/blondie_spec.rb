require File.expand_path('../spec_helper', __FILE__)

describe Blondie do
  describe '.allow_scopes' do
    before do
      @klass = Class.new
      @klass.extend Blondie
    end
    it "should set allowed scopes" do
      @klass.allow_scopes a: 1, b: 2
      @klass.instance_variable_get(:@allowed_scopes).should == {'a' => 1, 'b' => 2}
    end
    it "should add scopes to allowed scopes" do
      @klass.allow_scopes a: 1, b: 2
      @klass.allow_scopes c: 3, d: 4
      @klass.instance_variable_get(:@allowed_scopes).should == {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4}
    end
  end
  describe '.allowed_scopes' do
    before do
      @klass = Class.new
      @klass.extend Blondie
    end
    context "when no scopes are allowed" do
      it "should return an empty array" do
        @klass.allowed_scopes.should == {}
      end
    end
    context "when scopes are allowed" do
      it "should return allowed scopes" do
        @klass.allow_scopes :a => 1, :b => 2
        @klass.allowed_scopes.should == {'a' => 1, 'b' => 2}
      end
    end
  end
end

describe Blondie::ConditionString do
  context "when the condition is an allowed scope" do
    it "should allow the use of the scope" do
      cs = Blondie::ConditionString.new(User, 'active').parse!
      cs.operator.should == :active
      cs.associations.should == []
      cs.column_name.should be_nil
      cs.modifier.should be_nil
      cs.klass.should == User
    end
  end
  context "when the condition is a column name with an operator" do
    it "should set the right operator and column" do
      cs = Blondie::ConditionString.new(User, 'name_equals').parse!
      cs.operator.should == 'equals'
      cs.column_name.should == 'name'
      cs.klass.should == User
      cs.associations.should == []
      cs.modifier.should be_nil
    end
    context "when operator has a modifier" do
      it "should set the modifier" do
        cs = Blondie::ConditionString.new(User, 'name_equals_any').parse!
        cs.operator.should == 'equals'
        cs.column_name.should == 'name'
        cs.klass.should == User
        cs.associations.should == []
        cs.modifier.should == 'any'
      end
    end
  end
  context "when the condition is about associations" do
    context "when the condition is an allowed scope" do
      it "should allow the use of the scope" do
        cs = Blondie::ConditionString.new(User, 'posts_comments_anonymous').parse!
        cs.operator.should == :anonymous
        cs.associations.should == [:posts, :comments]
        cs.column_name.should be_nil
        cs.modifier.should be_nil
        cs.klass.should == Comment
      end
    end
    context "when the condition is a column name with an operator" do
      it "should set the right operator and column" do
        cs = Blondie::ConditionString.new(User, 'posts_comments_author_equals').parse!
        cs.operator.should == 'equals'
        cs.column_name.should == 'author'
        cs.klass.should == Comment
        cs.associations.should == [:posts, :comments]
        cs.modifier.should be_nil
      end
      context "when operator has a modifier" do
        it "should set the modifier" do
          cs = Blondie::ConditionString.new(User, 'posts_comments_author_equals_any').parse!
          cs.operator.should == 'equals'
          cs.column_name.should == 'author'
          cs.klass.should == Comment
          cs.associations.should == [:posts, :comments]
          cs.modifier.should == 'any'
        end
      end
    end
  end
  context "when condition is not an allowed scope" do
    it "should raise an error" do
      lambda do
        Blondie::ConditionString.new(User, :inactive).parse!
      end.should raise_error Blondie::ConditionNotParsedError
    end
  end
  context "when condition can't be parsed" do
    it "should raise an error" do
      ["comments_author_like", "birthday_is", "name_looks_like"].each do |condition|
        lambda do
          Blondie::ConditionString.new(User, condition).parse!
        end.should raise_error Blondie::ConditionNotParsedError
      end
    end
  end
end

describe Blondie::SearchProxy do

  describe "#result" do

    context "when search options are nil" do
      it "should not raise an error" do
        User.search(nil).result.to_sql.should == %(SELECT "users".* FROM "users")
      end
    end

    context "when condition is a scope" do
      context "when scope accepts no arguments" do
        it "should ignore scope if value is not '1'" do
          User.search(active: '0').result.to_sql.should == %(SELECT "users".* FROM "users")
        end
        it "should apply scope if value is '1'" do
          User.search(active: '1').result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE "users"."active" = 't')
        end
      end
      context "when scope accepts an argument" do
        it "should pass value to the scope" do
          User.search(id_in_list: '1,2,3').result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE "users"."id" IN (1, 2, 3))
        end
      end
    end

    context "when condition applies to the original class" do
      it "should understand condition that is a scope" do
        User.search(active: '1').result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE "users"."active" = 't')
      end

      describe "the 'like' operator" do
        it "should understand the 'like' operator without modifier" do
          User.search(name_like: 'toto').result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE ((("users"."name" LIKE '%toto%'))))
        end
        it "should understand the 'like' operator with the 'any' modifier" do
          User.search(name_like_any: ['toto','tutu']).result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE ((("users"."name" LIKE '%toto%') OR ("users"."name" LIKE '%tutu%'))))
        end
        it "should understand the 'like' operator with the 'all' modifier" do
          User.search(name_like_all: ['toto','tutu']).result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE ((("users"."name" LIKE '%toto%') AND ("users"."name" LIKE '%tutu%'))))
        end
      end

      describe "the 'equals' operator" do
        it "should understand the 'equals' operator without modifier" do
          User.search(name_equals: 'toto').result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE ("users"."name" = 'toto'))
        end
        it "should understand the 'equals' operator with the 'any' modifier" do
          User.search(name_equals_any: ['toto','tutu']).result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE (("users"."name" IN ('toto','tutu'))))
        end
        it "should understand the 'equals' operator with the 'all' modifier" do
          User.search(name_equals_all: ['toto','tutu']).result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE ("users"."name" = 'toto' AND "users"."name" = 'tutu'))
        end
        it "should typecast values if needed" do
          User.search(posts_count_equals: '2').result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE ("users"."posts_count" = 2))
        end
      end

      context "when condition has 'or' in it" do
        it "should understand full syntax" do
          User.search(name_like_or_login_equals: 'toto').result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE ((("users"."name" LIKE '%toto%')) OR "users"."login" = 'toto'))
        end
        it "should understand partial syntaxt" do
          User.search(name_or_login_like: 'toto').result.to_sql.should == %(SELECT "users".* FROM "users"  WHERE ((("users"."name" LIKE '%toto%')) OR (("users"."login" LIKE '%toto%'))))
        end
      end

    end

    context "when condition applies to an association" do

      it "should understand condition that is a scope" do
        User.search(posts_published: '1').result.to_sql.should == %(SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id" WHERE "posts"."published" = 't')
      end

      it "should understand the 'like' operator" do
        User.search(posts_title_like: 'tutu').result.to_sql.should == %(SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id" WHERE ((("posts"."title" LIKE '%tutu%'))))
      end

      it "should understand the 'equals' operator" do
        User.search(posts_title_equals: 'tutu').result.to_sql.should == %(SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id" WHERE ("posts"."title" = 'tutu'))
      end

      it "should not join multiple times" do
        User.search(posts_title_equals: 'tutu', posts_published: '1').result.to_sql.should == %(SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id" WHERE ("posts"."title" = 'tutu') AND "posts"."published" = 't')
      end

      it "should chain associations" do
        User.search(posts_comments_anonymous: '1').result.to_sql.should == %(SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id" INNER JOIN "comments" ON "comments"."post_id" = "posts"."id" WHERE ("author" IS NULL))
      end

      context "when condition has 'or' in it" do
        it "should understand full syntax" do
          User.search(posts_favorite_count_equals_or_posts_share_count_equals: 10).result.to_sql.should == %(SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id" WHERE ("posts"."favorite_count" = 10 OR "posts"."share_count" = 10))
        end
        it "should understand partial syntaxt" do
          User.search(posts_favorite_count_or_posts_share_count_equals: 10).result.to_sql.should == %(SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id" WHERE ("posts"."favorite_count" = 10 OR "posts"."share_count" = 10))
        end
      end
    end

  end

end
