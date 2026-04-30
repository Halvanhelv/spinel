# Test instance_eval { block } block-form lifting.
# Each section's output is compared against CRuby by `make test`.

class Config
  attr_accessor :port, :host, :debug

  def initialize
    @port = 0
    @host = ""
    @debug = false
  end
end

# ---- 1. Top-level basic form ----
cfg = Config.new
cfg.instance_eval do
  self.port = 8080
  self.host = "localhost"
  self.debug = true
end
puts cfg.port    # 8080
puts cfg.host    # localhost
puts cfg.debug   # true

# ---- 2. Two instance_eval calls in sequence (same object) ----
cfg.instance_eval do
  self.port = 9090
end
puts cfg.port    # 9090

# ---- 3. Methods called inside the block dispatch through self ----
class Routes
  attr_accessor :entries

  def initialize
    @entries = "init".split(",")  # StrArray hint
    @entries.pop                  # start empty
  end

  def get(path)
    @entries.push("GET " + path)
  end

  def post(path)
    @entries.push("POST " + path)
  end
end

app = Routes.new
app.instance_eval do
  get("/")
  get("/about")
  post("/login")
end
i = 0
while i < app.entries.length
  puts app.entries[i]
  i = i + 1
end

# ---- 4. instance_eval inside a top-level while loop ----
counter = Config.new
i = 0
while i < 3
  counter.instance_eval do
    self.port = self.port + 1
  end
  i = i + 1
end
puts counter.port  # 3

# ---- 5. instance_eval inside a top-level if branch ----
flag = Config.new
cond = 1
if cond > 0
  flag.instance_eval do
    self.debug = true
  end
end
puts flag.debug  # true

# ---- 6. Different objects of different classes interleaved ----
a = Config.new
b = Routes.new
a.instance_eval { self.port = 1 }
b.instance_eval { get("/x") }
a.instance_eval { self.port = 2 }
b.instance_eval { post("/y") }
puts a.port              # 2
puts b.entries.length    # 2
puts b.entries[0]        # GET /x
puts b.entries[1]        # POST /y

# ---- 7. Reassignment to another instance of the same class ----
fresh = Config.new
fresh.instance_eval { self.port = 11 }
puts fresh.port  # 11
fresh = Config.new
fresh.instance_eval { self.port = 22 }
puts fresh.port  # 22
