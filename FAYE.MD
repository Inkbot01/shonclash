# Faye UI Framework Documentation

Faye is a declarative, reactive UI framework for Roblox that works directly with native Roblox instances. It provides state management, animations, automatic cleanup, and reactive data binding.

**Location:** [src/shared/Modules/Shared/Faye](shared/Modules/Shared/Faye)

**External Docs:** https://mountaindouw.github.io/Faye/

## Core Concept: Threads

A **Thread** is the foundation of Faye. It:
- Contains and manages UI components
- Handles automatic cleanup when destroyed
- Provides all Faye methods

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Faye = require(ReplicatedStorage.Faye)

-- Create a new Thread
local Thread = Faye.new()

-- All Faye features are accessed through Thread
local Value = Thread:Value(0)
local Frame = Thread:Create("Frame")({ ... })

-- Cleanup everything when done
Thread:Destroy()
```

## Creating Instances

### Thread:Create(ClassName)
Creates a new Roblox instance with Faye's reactive system.

```lua
local Frame = Thread:Create("Frame")({
    Name = "MyFrame",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(1, 1, 1),
    Parent = PlayerGui,

    -- Children are nested inside the props table
    Thread:Create("UICorner")({
        CornerRadius = UDim.new(0.1, 0),
    }),

    Thread:Create("TextLabel")({
        Text = "Hello World",
        Size = UDim2.fromScale(0.5, 0.5),
    }),
})

-- Access the underlying Instance
local instance = Frame.Instance
```

**Key Rule:** The first element in the hierarchy needs a `Parent` property. All nested children automatically inherit their parent.

### Thread:Configure(Entity)
Applies Faye utilities to an existing Roblox instance.

```lua
local existingFrame = workspace.SomeFrame

Thread:Configure(existingFrame)({
    Size = Thread:Animation(SizeValue, SpringInfo),
    BackgroundColor3 = someColorValue,
})
```

## Properties Table

### Static Properties
Regular Roblox properties are set directly:

```lua
Thread:Create("Frame")({
    Name = "MyFrame",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 0.5,
    Visible = true,
})
```

### Dynamic Properties (Values)
Pass a Value object for reactive updates:

```lua
local Visible = Thread:Value(true)
local Size = Thread:Value(UDim2.fromScale(1, 1))

Thread:Create("Frame")({
    Visible = Visible,           -- Updates when Visible:Set() is called
    Size = Size,                 -- Updates when Size:Set() is called
})

-- Later...
Visible:Set(false)  -- Frame becomes invisibl  resizes
```

### Animated Properties
Use `Thread:Animation()` for smooth transitions:

```lua
local Size = Thread:Value(UDim2.fromScale(1, 1))

Thread:Create("Frame")({
    Size = Thread:Animation(Size, Thread.SpringInfo(0.5, 0.75, 0.4)),
})

Size:Set(UDim2.fromScale(0.5, 0.5))  -- Animates smoothly
```

### Function Properties
Functions execute once when the instance is created. Return a value to set the property:

```lua
Thread:Create("TextLabel")({
    Size = function()
        local nameLength = #playerName
        return UDim2.fromScale(math.min(0.9, 0.12 * nameLength), 0.45)
    end,
})
```

For access to the created entity, receive it as a parameter:

```lua
Thread:Create("Frame")({
    After = function(Entity)
        -- Entity is the created Frame instance
        Entity:SetAttribute("CustomData", 123)

        -- Return children to add
        return Thread:Create("TextLabel")({
            Text = "Created after parent",
        })
    end,
})
```

### Special Properties

#### `Parent`
Sets the parent instance. Required for the root element.

```lua
Thread:Create("Frame")({
    Parent = PlayerGui.ScreenGui,
})
```

#### `After`
Content to add AFTER the instance is created. Can be a table of children or a function:

```lua
Thread:Create("Frame")({
    After = {
        Thread:Create("TextLabel")({ Text = "Child 1" }),
        Thread:Create("TextLabel")({ Text = "Child 2" }),

        function(Entity)
            -- Conditional child
            if someCondition then
                return Thread:Create("Frame")({ Name = "Conditional" })
            end
        end,
    },
})
```

#### `Before`
Content to create BEFORE this instance. Useful for ordering:

```lua
Thread:Create("Frame")({
    Before = {
        SomeOtherFrame,
    },
})
```

#### `Properties`
Alternative way to pass properties (merged into main props):

```lua
Thread:Create("Frame")({
    Properties = {
        Name = "MyFrame",
        Size = UDim2.fromScale(1, 1),
    },
})
```

### Instance Events
Events are passed as functions. The first parameter is always the Instance:

```lua
Thread:Create("TextButton")({
    MouseButton1Click = function(Entity)
        print("Button clicked!")
    end,

    MouseEnter = function(Entity)
        -- Hover effect
    end,

    MouseLeave = function(Entity)
        -- Unhover effect
    end,

    MouseButton1Down = function(Entity)
        -- Mouse down
    end,

    MouseButton1Up = function(Entity)
        -- Mouse up
    end,
})
```

**Available Events:** `MouseEnter`, `MouseLeave`, `MouseMoved`, `MouseButton1Click`, `MouseButton2Click`, `MouseButton1Down`, `MouseButton1Up`, `MouseButton2Down`, `MouseButton2Up`, `MouseWheelForward`, `MouseWheelBackward`, `InputBegan`, `InputEnded`, `InputChanged`, `Activated`, `Deactivated`, `Equipped`, `Unequipped`, `Focused`, `FocusLost`, etc.

## Values

### Thread:Value(initial)
Creates a reactive value that triggers updates when changed.

```lua
local Count = Thread:Value(0)
local Name = Thread:Value("Player")
local Items = Thread:Value({})
local IsEnabled = Thread:Value(true)
```

### Value Methods

#### :Get()
Returns the current value:
```lua
local current = Count:Get()  -- 0
```

#### :Set(newValue, signalIsBasic?)
Sets a new value and fires Changed signal:
```lua
Count:Set(10)
Name:Set("NewName")
```

#### :Reset()
Resets to the initial value:
```lua
Count:Set(50)
Count:Reset()  -- Back to 0
```

#### :Add(value, ...)
For numbers, adds to the value. For tables, adds an item:
```lua
Count:Add(5)  -- Count is now 5

Items:Add("sword")  -- Adds "sword" to Items table
Items:Add("key", "value")  -- Adds Items["key"] = "value"
```

#### :Remove(value)
For numbers, subtracts from the value. For tables, removes an item:
```lua
Count:Remove(3)  -- Subtracts 3

Items:Remove("sword")  -- Removes "sword" from Items table
```

#### :Compare(value)
Compares current value with given value:
```lua
if Count:Compare(10) then
    print("Count is 10!")
end
```

#### :Refresh()
Fires the Changed signal without changing the value:
```lua
Count:Refresh()  -- Triggers all listeners
```

#### :GetItem(index)
For table values, gets an item by index:
```lua
local item = Items:GetItem("key")
```

#### :ItemExists(entity)
For table values, checks if an item exists:
```lua
if Items:ItemExists("sword") then
    print("Has sword!")
end
```

### Value.Changed
Signal that fires when the value changes:
```lua
Thread:Connect(Count.Changed, function(newValue)
    print("Count changed to:", newValue)
end)
```

### Operator Overloads
Values support `+` and `-` operators:
```lua
Count = Count + 5   -- Same as Count:Add(5)
Count = Count - 3   -- Same as Count:Remove(3)
```

## Animation System

### Thread:Animation(goal, info?, modifications?)
Creates an animated value that smoothly transitions to the goal.

```lua
local Size = Thread:Value(UDim2.fromScale(1, 1))

Thread:Create("Frame")({
    Size = Thread:Animation(Size, Thread.SpringInfo(0.5, 0.75, 0.4)),
})

-- When Size changes, the frame animates smoothly
Size:Set(UDim2.fromScale(0.5, 0.5))
```

### Thread.Info(time, style?, direction?, repeatCount?, reverse?, delayTime?)
Creates TweenInfo-like animation configuration:

```lua
-- Parameters:
-- time: number (default 1)
-- style: Enum.EasingStyle (default Linear)
-- direction: Enum.EasingDirection (default Out)
-- repeatCount: number (default 0)
-- reverse: boolean (default false)
-- delayTime: number (default 0)

local QuickSine = Thread.Info(0.15, Enum.EasingStyle.Sine)
local MediumBack = Thread.Info(0.25, Enum.EasingStyle.Back)
local LongQuad = Thread.Info(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
```

### Thread.SpringInfo(time, frequency?, damping?, repeatCount?, reverse?, delayTime?)
Creates spring-based animation configuration:

```lua
-- Parameters:
-- time: number (default 1)
-- frequency: number (default 1) - Higher = faster oscillation
-- damping: number (default 0.2) - Higher = less bounce (0-1)
-- repeatCount: number (default 0)
-- reverse: boolean (default false)
-- delayTime: number (default 0)

local StrongSpring = Thread.SpringInfo(0.15, 0.75, 0.4)
local NormalSpring = Thread.SpringInfo(0.5, 0.5, 0.5)
local BouncySpring = Thread.SpringInfo(0.5, 1, 0.2)
```

### Animation Modifications
The third parameter to `Thread:Animation()` provides modifications:

```lua
Thread:Animation(Value, Info, {
    From = startValue,           -- Initial value (plays entry animation)
    AlwaysFrom = startValue,     -- Always start from this value
    FirstGoal = firstTarget,     -- First animation goes to this value
    FirstInfo = firstAnimInfo,   -- Use different info for first animation
    FirstDelayTime = 0.5,        -- Delay before first animation
})
```

**Common Pattern - Entry Animation:**
```lua
Thread:Create("Frame")({
    Size = Thread:Animation(Size, HoverInfo, {
        From = UDim2.new(),  -- Starts at 0 and animates to current Size
        FirstInfo = FirstHoverInfo  -- Different timing for entry
    }),
})
```

### Animation Methods

#### :Stop()
Stops the animation immediately:
```lua
local anim = Thread:Animation(Value, Info)
anim:Stop()
```

#### :Skip()
Immediately applies the goal state:
```lua
anim:Skip()
```

#### :Destroy()
Cleans up the animation:
```lua
anim:Destroy()
```

### Thread:LoadAnimation(entity, goals, info?)
Creates an animation that can be played on demand (imperative style):

```lua
local anim = Thread:LoadAnimation(button, {
    BackgroundColor3 = Color3.new(1, 0, 0),
    Size = UDim2.fromScale(1.1, 1.1),
}, Thread.Info(0.2, Enum.EasingStyle.Sine))

anim:Play()   -- Play the animation
anim:Stop()   -- Stop
anim:Pause()  -- Pause
anim:Resume() -- Resume
anim:Skip()   -- Skip to end
```

## Reactive Functions

### Thread:Do(func)
Runs once during compilation. Grab values to make it reactive:

```lua
Thread:Create("Frame")({
    BackgroundTransparency = Thread:Do(function(Grab)
        local isDragging = Grab(DraggingValue)
        return if isDragging then 0.6 else 1
    end),

    Visible = Thread:Do(function(Grab)
        local bagOpen = Grab(BagOpenValue)
        return bagOpen
    end),
})
```

**Note:** `Thread:Do` re-runs whenever any grabbed value changes.

### Thread:State(func)
Like `Thread:Do`, but **destroys and recreates** children when values change:

```lua
Thread:Create("Frame")({
    Thread:State(function(Grab, InnerThread, Entity)
        local items = Grab(ItemsValue)

        -- This entire block is recreated when ItemsValue changes
        for _, item in items do
            InnerThread:Create("TextLabel")({
                Text = item.name,
                Parent = Entity,
            })
        end
    end),
})
```

**Difference from Do:**
- `Do` - Updates property values in place
- `State` - Destroys old children and creates new ones

### Thread:Reactive(func)
Creates a reactive function that re-runs when grabbed values change:

```lua
Thread:Reactive(function(Grab)
    local dragging = Grab(RealDragging)
    local down = Grab(MouseDown)
    local hovering = Grab(Hovering)

    if (dragging or hovering) and (not down or dragging) then
        Scale:Set(Scale.Initial * 1.125)
        return
    end

    Scale:Reset()
end)
```

**Use Case:** Logic that needs to run outside of instance properties.

## Iteration

### Thread:Iterate(table, func)
Reactive iterator that recreates ALL children when the table changes:

```lua
local Items = Thread:Value({ "sword", "shield", "potion" })

Thread:Create("Frame")({
    Thread:Iterate(Items, function(Index, Value, InnerThread, Entity)
        return InnerThread:Create("TextLabel")({
            Text = Value,
            LayoutOrder = Index,
        })
    end),
})

-- When Items changes, all children are recreated
Items:Add("bow")
```

### Thread:AdvancedIterate(table, func)
Smarter iterator that only updates CHANGED items:

```lua
local Slots = Thread:Value({})

Thread:Create("Frame")({
    Thread:AdvancedIterate(Slots, function(Index, Value, InnerThread, Entity)
        -- InnerThread is destroyed when this specific item is removed
        InnerThread:Add(function()
            -- Cleanup when this item is removed
            if HoveredSlot:Get() == Index then
                HoveredSlot:Reset()
            end
        end)

        return InnerThread:Create("Frame")({
            Name = "Slot_" .. Index,
        })
    end),
})

-- Only adds new item, doesn't recreate existing ones
Slots:Add("newItem", 5)

-- Only removes that specific item
Slots:Remove(5)
```

**Use `Iterate`** when you need to recreate everything on change.
**Use `AdvancedIterate`** when you want incremental updates.

## Signals

### Thread:Signal(connections, func)
Creates a reactive signal handler that runs and returns children:

```lua
Thread:Create("Frame")({
    Thread:Signal(SomeEvent, function(InnerThread, Entity, ...eventArgs)
        -- Create temporary effect when event fires
        return {
            InnerThread:Create("Frame")({
                Name = "Effect",
                -- Effect children...
            })
        }
    end),
})
```

**Pattern - Stack Change Effect:**
```lua
Thread:Signal(Stack.StackChanged, function(_, _, newStack: number)
    local changeAmount = newStack - lastStack
    lastStack = newStack

    -- Return effect component that shows +/- amount
    return { StackChangeEffect(Thread, changeAmount, Entity) }
end),
```

### Thread:SignalState(connections, func)
Like `Signal`, but destroys previous children before creating new ones:

```lua
Thread:SignalState(ValueChanged, function(InnerThread, Entity, newValue)
    -- Previous children are destroyed
    return InnerThread:Create("TextLabel")({
        Text = tostring(newValue),
    })
end)
```

## DelayValue

### Thread:DelayValue(value, time)
Creates a delayed version of a Value that waits before updating:

```lua
local Visible = Thread:Value(true)
local DelayedVisible = Thread:DelayValue(Visible, 0.5)

Thread:Create("Frame")({
    Visible = DelayedVisible,  -- Waits 0.5s after Visible changes
})

-- Useful for exit animations:
local InInfo = Thread.Info(0.175, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local RealVisibility = Thread:DelayValue(Visible, InInfo.Time):Sensitive():For(true, 0)
-- :Sensitive() - Cancels pending updates if new update comes in
-- :For(true, 0) - No delay when setting to true (instant show, delayed hide)
```

### DelayValue Methods

#### :Set(value)
Sets the underlying value:
```lua
DelayedValue:Set(newValue)
```

#### :SetTime(time)
Changes the delay time:
```lua
DelayedValue:SetTime(0.3)
```

#### :ResetTime()
Resets to original delay time:
```lua
DelayedValue:ResetTime()
```

#### :Sensitive()
Makes the delay value cancel pending updates when new updates arrive:
```lua
DelayedValue:Sensitive()
```

#### :For(value, time)
Sets a custom delay for a specific value:
```lua
DelayedValue:For(true, 0)   -- No delay when setting to true
DelayedValue:For(false, 0.3) -- 0.3s delay when setting to false
```

## Space (Task Management)

### Thread:Space(func)
Creates a task manager for controlling multiple related operations:

```lua
local HoverSpace = Thread:Space(function(isHovering, button)
    if isHovering then
        button.BackgroundColor3 = Color3.new(1, 1, 1)
    else
        button.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    end
end)

-- Add tasks to the space
local task1 = HoverSpace:Add({ isHovering, button1 })
local task2 = HoverSpace:Add({ isHovering, button2 })

-- Call all tasks
HoverSpace:Call()

-- Call specific task by ID
task1:SetId("button1")
HoverSpace:Call("button1")

-- Connect signal to space
HoverSpace:Connect(SomeSignal)
```

### Space Methods

#### :Add(params, thread?, noUnpack?)
Adds a task to the space:
```lua
local task = Space:Add({ param1, param2 })
```

#### :Remove(task)
Removes a task:
```lua
Space:Remove(task)
```

#### :Call(id?)
Calls all tasks, or a specific one by ID:
```lua
Space:Call()        -- All tasks
Space:Call("myId")  -- Specific task
```

#### :Connect(signal, id?)
Connects a signal to call tasks:
```lua
Space:Connect(Heartbeat)
Space:Connect(SomeEvent, "specificTask")
```

### Task Methods

#### :SetId(id)
Sets an ID for targeted calls:
```lua
task:SetId("myTask")
```

#### :Call()
Calls this specific task:
```lua
task:Call()
```

#### :Connect(signal)
Connects a signal to this task:
```lua
task:Connect(SomeEvent)
```

#### :AddParameter(index, value)
Adds parameters to the task:
```lua
task:AddParameter("extraData", someValue)
```

## Cleanup and Lifecycle

### Thread:Add(entity)
Adds an entity to be cleaned up with the Thread:
```lua
local connection = SomeEvent:Connect(handler)
Thread:Add(connection)

local cleanup = function() print("Cleaned!") end
Thread:Add(cleanup)
```

### Thread:Remove(entity)
Removes an entity from cleanup:
```lua
Thread:Remove(connection)
```

### Thread:Connect(signal, func)
Connects to a signal with automatic cleanup:
```lua
Thread:Connect(Player.CharacterAdded, function(character)
    -- Handle character
end)
```

### Thread:Spawn(func, ...)
Spawns a task with automatic cleanup:
```lua
Thread:Spawn(function(param1)
    -- Async work
end, arg1)
```

### Thread:Delay(time, func, ...)
Delays execution with automatic cleanup:
```lua
Thread:Delay(2, function()
    print("2 seconds later!")
end)
```

### Thread:Debris(item, lifetime)
Destroys an item after a delay:
```lua
Thread:Debris(particle, 2)  -- Destroyed after 2 seconds
```

### Thread:Schedule(time, item, ...)
Cleans up or calls an item after time:
```lua
Thread:Schedule(1, connection)  -- Disconnects after 1 second
Thread:Schedule(2, someFunction, arg1)  -- Calls function after 2 seconds
```

### Thread:Extend(noAttachment?)
Creates a sub-thread:
```lua
local subThread = Thread:Extend()
-- subThread is cleaned when Thread is destroyed

local independentThread = Thread:Extend(true)
-- independentThread is NOT cleaned with parent
```

### CleanDelay Property
Delays cleanup of an instance for exit animations:

```lua
Thread:Create("Frame")({
    CleanDelay = 0.5,  -- Waits 0.5s before destroying

    -- Can also be a function:
    CleanDelay = function()
        return if bagOpen then 0 else 0.2
    end,
})
```

### CleanFunction Property
Defines exit animation properties:

```lua
Thread:Create("Frame")({
    CleanDelay = 0.3,

    CleanFunction = function(InnerThread, Entity)
        -- Configure exit animation
        InnerThread:Configure(Entity)({
            Size = InnerThread:Animation(UDim2.new(), CleanInfo),
            BackgroundTransparency = InnerThread:Animation(1, CleanInfo),
        })
    end,
})
```

## Utility Functions

### Thread:InstancePropertySync(instance, property)
Creates a Value synced to an instance property:
```lua
local SizeValue = Thread:InstancePropertySync(frame, "Size")
-- SizeValue updates when frame.Size changes
```

### Thread:InstanceAttributeSync(instance, attribute)
Creates a Value synced to an instance attribute:
```lua
local HealthValue = Thread:InstanceAttributeSync(character, "Health")
```

### Thread:Listener(entity, events, func)
Listens to multiple events on an entity:
```lua
Thread:Listener(button, { "MouseEnter", "MouseLeave" }, function(eventName, ...)
    if eventName == "MouseEnter" then
        -- Handle enter
    else
        -- Handle leave
    end
end)
```

### Thread:SetTo(value)
Wraps a Value for use in props that expect static values:
```lua
Thread:Create("Frame")({
    Parent = Thread:SetTo(ParentValue),
})
```

### Thread:YieldSafe(func, delayTime?)
Creates a yield-safe function that can include waits/yields. Used within props tables or standalone:

```lua
-- Within props table - runs after instance is created
Thread:Create("Frame")({
    Thread:YieldSafe(function()
        task.wait(1)
        -- Do something after 1 second
        -- Safe even if Thread is destroyed during wait
    end),

    -- With delay before starting
    Thread:YieldSafe(function()
        -- This runs after 0.5s delay
    end, 0.5),
})

-- Standalone usage
Thread:YieldSafe(function()
    task.wait(2)
    -- Async work that auto-cleans with Thread
end)
```

**Parameters:**
- `func` - Function to run (can contain yields)
- `delayTime` - Optional delay before running the function

**Use Case:** Run async code that should be cleaned up if the Thread is destroyed.

### Thread.CloneTable(table, cloneFunction?)
Deep clones a table:
```lua
local cloned = Thread.CloneTable(originalTable)

-- With custom clone function
local cloned = Thread.CloneTable(original, function(index, value)
    return index, value  -- Return modified key/value
end)
```

### Thread:MethodSignaled(method, index, runOnInitialization?)
Listens to property/attribute change signals on an instance. Used within props tables:

```lua
Thread:Create("Frame")({
    -- Listen to Size property changes
    Thread:MethodSignaled("GetPropertyChangedSignal", "Size", true),

    -- Listen to attribute changes
    Thread:MethodSignaled("GetAttributeChangedSignal", "Health"),
})
```

**Parameters:**
- `method` - The signal method name (`"GetPropertyChangedSignal"` or `"GetAttributeChangedSignal"`)
- `index` - The property/attribute name to listen to
- `runOnInitialization` - If true, runs immediately when compiled (default: false)

**Use Case:** React to property/attribute changes on the created instance.

### Thread:SpecialThread(func, params)
Creates a special thread with custom lifecycle settings. Used within props tables:

```lua
Thread:Create("Frame")({
    -- Thread that auto-destroys after 2 seconds
    Thread:SpecialThread(function(InnerThread, Entity)
        InnerThread:Create("TextLabel")({
            Text = "Temporary content",
            Parent = Entity,
        })
    end, {
        Lifetime = 2,      -- Auto-destroy after 2 seconds
        YieldSafe = true,  -- Allow yields in the function
    }),

    -- Shorthand: just pass lifetime as number
    Thread:SpecialThread(function(InnerThread, Entity)
        -- Content
    end, 5),  -- 5 second lifetime
})
```

**Parameters:**
- `func` - Function receiving `(InnerThread, Entity)`
- `params` - Either a number (lifetime) or table with:
  - `Lifetime: number` - Time before auto-cleanup
  - `YieldSafe: boolean?` - Allow yields in the function

**Use Case:** Temporary UI elements that should auto-clean after a duration.

### Thread:DelayProperty(props, time, from?)
Delays compilation of properties. Used within props tables for staggered animations:

```lua
Thread:Create("Frame")({
    Size = UDim2.fromScale(0, 0),  -- Initial size

    -- After 0.5 seconds, these properties get applied
    Thread:DelayProperty({
        Size = Thread:Animation(UDim2.fromScale(1, 1), SpringInfo),
        BackgroundTransparency = Thread:Animation(0, Info),
    }, 0.5, {
        -- Optional: "From" properties applied before delay
        Size = UDim2.fromScale(0, 0),
    }),
})
```

**Parameters:**
- `props` - Properties to compile after the delay
- `time` - Delay in seconds
- `from` - Optional initial properties to apply immediately

**Use Case:** Staggered entry animations, delayed property changes.

### Thread.ModifyAnimation(animation, modifications)
Modifies an existing animation object in place. Static method (no Thread needed):

```lua
local anim = Thread:Animation(SomeValue, Info)

-- Modify the animation later
Thread.ModifyAnimation(anim, {
    From = startValue,
    AlwaysFrom = true,
    FirstGoal = firstTarget,
    FirstInfo = differentInfo,
    FirstDelayTime = 0.5,
})
```

**Note:** Does not work with animations created via `Thread:LoadAnimation()`.

### Thread:CloneAnimation(animation, modifications?)
Clones an existing animation with optional modifications:

```lua
local baseAnim = Thread:Animation(Value, SpringInfo)

-- Clone with different modifications
local clonedAnim = Thread:CloneAnimation(baseAnim, {
    From = differentStartValue,
    FirstInfo = differentInfo,
})

Thread:Create("Frame")({
    Size = clonedAnim,  -- Uses the cloned animation
})
```

**Use Case:** Reuse animation configurations across multiple elements with slight variations.

## Component Pattern

UI components are structured as functions that return Faye instances.

### Basic Component Structure
```lua
-- Components/Buttons/MyButton.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FayeTypes = require(ReplicatedStorage.Modules.Shared.Faye)

return function(
    Thread: FayeTypes.Thread,
    OnClick: () -> (),
    Properties: { [any]: any }
)
    local Hovering = false
    local Size = Thread:Value(UDim2.fromScale(1, 1))

    local MouseEnter = function()
        Hovering = true
        Size:Set(UDim2.fromScale(1.05, 1.05))
    end

    local MouseLeave = function()
        Hovering = false
        Size:Reset()
    end

    return Thread:Create("TextButton")({
        MouseButton1Click = OnClick,
        MouseEnter = MouseEnter,
        MouseLeave = MouseLeave,

        After = Properties,  -- Allow custom properties

        Size = Thread:Animation(Size, Thread.SpringInfo(0.15, 0.75, 0.4)),
        AutoButtonColor = false,

        Thread:Create("UICorner")({
            CornerRadius = UDim.new(0.2, 0),
        }),
    })
end
```

### Using Components
```lua
local MyButton = require(path.to.MyButton)

Thread:Create("Frame")({
    Parent = ScreenGui,

    MyButton(Thread, function()
        print("Clicked!")
    end, {
        Text = "Click Me",
        Position = UDim2.fromScale(0.5, 0.5),
    }),
})
```

### Component with Cleanup
```lua
return function(Thread, ...)
    local InnerThread = Thread:Extend()

    -- Component using InnerThread
    local Frame = InnerThread:Create("Frame")({
        -- ...
    })

    -- Return both the UI and cleanup function
    return Frame, function()
        InnerThread:Destroy()
    end
end
```

## Common Patterns

### Hover Effect (Outsourced Hover)
```lua
local Hovering = Thread:Value(false)
local Size = Thread:Value(UDim2.fromScale(1, 1))

-- React to hover state
Thread:Connect(Hovering.Changed, function()
    if Hovering:Get() then
        Size:Set(UDim2.fromScale(1.1, 1.1))
    else
        Size:Reset()
    end
end)

Thread:Create("TextButton")({
    Size = Thread:Animation(Size, Thread.SpringInfo(0.15, 0.75, 0.4)),

    MouseEnter = function()
        Hovering:Set(true)
    end,
    MouseLeave = function()
        Hovering:Set(false)
    end,
})
```

### Entry/Exit Animations
```lua
local Visible = Thread:Value(true)
local Position = Thread:Value(UDim2.fromScale(0.5, 0.5))

local InInfo = Thread.Info(0.175, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local OutInfo = Thread.Info(0.175, Enum.EasingStyle.Back)
local VisibleInfo = Thread:Value(OutInfo)

-- Delayed visibility for exit animation
local RealVisibility = Thread:DelayValue(Visible, InInfo.Time):Sensitive():For(true, 0)

Thread:Connect(Visible.Changed, function()
    if Visible:Get() then
        VisibleInfo:Set(OutInfo)
        Position:Reset()
    else
        VisibleInfo:Set(InInfo)
        Position:Set(UDim2.fromScale(0.5, 1.5))  -- Slide out
    end
end)

Thread:Create("Frame")({
    Visible = RealVisibility,
    Position = Thread:Animation(Position, VisibleInfo, { From = UDim2.fromScale(0.5, 1.5) }),
})
```

### Conditional Children
```lua
Thread:Create("Frame")({
    After = function(Entity)
        if someCondition then
            return Thread:Create("TextLabel")({
                Text = "Conditional content",
            })
        end
        return nil  -- No child if condition false
    end,
})
```

### Dynamic Color Updates
```lua
local BaseColor = Thread:Value(Color3.new(1, 0, 0))
local DarkColor = Thread:Value(Color3.new(0.5, 0, 0))

Thread:Connect(BaseColor.Changed, function()
    local newColor = BaseColor:Get()
    DarkColor:Set(ColorService.makeDarker(newColor, 0.5))
end)

Thread:Create("Frame")({
    BackgroundColor3 = Thread:Animation(BaseColor, Thread.Info(0.2)),

    Thread:Create("Frame")({
        BackgroundColor3 = Thread:Animation(DarkColor, Thread.Info(0.2)),
    }),
})
```

### Multi-Reactive Logic
```lua
Thread:Reactive(function(Grab)
    local dragging = Grab(RealDragging)
    local mouseDown = Grab(MouseDown)
    local hovering = Grab(Hovering)

    -- Complex logic based on multiple values
    if (dragging or hovering) and (not mouseDown or dragging) then
        Scale:Set(Scale.Initial * 1.125)
    else
        Scale:Reset()
    end
end)
```

## FayeInfos Reference

Standard animation configurations used across the codebase (from [Client/UI/FayeInfos.luau](Shared/Modules/Client/UI/FayeInfos.luau)):

```lua
-- Linear
QuickLinear = Info(0.15, Enum.EasingStyle.Linear)

-- Sine
LongSine = Info(0.4, Enum.EasingStyle.Sine)
MediumSine = Info(0.25, Enum.EasingStyle.Sine)
QuickSine = Info(0.15, Enum.EasingStyle.Sine)

-- Quad
LongQuad = Info(0.35, Enum.EasingStyle.Quad)
MediumQuad = Info(0.25, Enum.EasingStyle.Quad)
QuickQuad = Info(0.15, Enum.EasingStyle.Quad)

-- Back (overshoot)
MediumBack = Info(0.25, Enum.EasingStyle.Back)
QuickBack = Info(0.15, Enum.EasingStyle.Back)

-- Springs
NormalSpring = SpringInfo(0.5, 0.5, 0.5)
StrongSpring = SpringInfo(0.15, 0.75, 0.4)

-- Appear/Disappear pairs
Appear = Info(0.175, Enum.EasingStyle.Back)
Disappear = Info(0.175, Enum.EasingStyle.Back, Enum.EasingDirection.In)
```

## File Organization

All UI modules should be placed under the appropriate category in [src/client/Client/ClientInit/UI/](client/Client/ClientInit/UI/):

```
Client/PlayerHandling
├──UiHandler            -- UI initialization
```

## Type Annotations

Always use FayeTypes for type safety:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FayeTypes = require(ReplicatedStorage.Modules.Shared.Faye.FayeTypes)

return function(
    Thread: FayeTypes.Thread,
    SomeValue: FayeTypes.Value,
    AnimInfo: FayeTypes.Info | FayeTypes.SpringInfo
)
    -- Implementation
end
```

**Available Types:**
- `FayeTypes.Thread`
- `FayeTypes.Value`
- `FayeTypes.Animation`
- `FayeTypes.Info`
- `FayeTypes.SpringInfo`
- `FayeTypes.FayeInstance`
- `FayeTypes.Properties`
- `FayeTypes.Space`
- `FayeTypes.SpaceTask`
- `FayeTypes.Signal`
- `FayeTypes.DelayValue`
- `FayeTypes.LoadAnimation`

---

# TextPlus Documentation

TextPlus (`src/shared/Modules/Shared/textplus/`) is a Roblox rich text animation library by MountainDouw. It renders animated, styled text by creating individual `TextLabel` instances per-word and per-letter, driven by a custom tag syntax.

**External Docs:** https://ouw2204.github.io/Text_plus/

**Access pattern (already loaded via Global):**
```lua
local TextPlus = global.SharedModules["textplus"]
```

---

## Core Concept

TextPlus parses a custom tag string, splits it into a sequence of styled segments, then either:
- **Plays** it character-by-character with enter animations (typewriter effect)
- **Prints** it all at once (instant render)
- **Measures** it without displaying (size queries)

Each word becomes a `TextLabel` container; each letter becomes a child `TextLabel` inside it. Animations run per-letter via `RunService.Heartbeat`.

---

## TextPlus.new

Creates a new TextPlus object. Does not render anything until you call `:Play()`, `:Print()`, or `:GetContentSize()`.

```lua
local obj = TextPlus.new(Content: string, DefaultSettings: DefaultSettingsType?)
```

### DefaultSettings Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `Size` | `number` | `14` | Base text size in pixels |
| `Color` | `Color3` | White | Base text color |
| `Font` | `Enum.Font` | `SourceSans` | Font enum (use `FontFace` for modern fonts) |
| `FontFace` | `Font` | `nil` | Overrides `Font` when set |
| `Transparency` | `number` | `0` | Base text transparency |
| `StrokeColor` | `Color3` | Black | Text stroke color |
| `StrokeTransparency` | `number` | `1` | Text stroke transparency (1 = invisible) |
| `Wrapped` | `boolean` | `true` | Word wrap within the parent frame |
| `Overfill` | `boolean` | `false` | If false, stops rendering when text exceeds parent height |
| `Scaled` | `boolean` | `false` | Scale text relative to parent frame size |
| `Scale` | `number` | `nil` | Scale multiplier when `Scaled = true` |
| `ContentScaled` | `boolean` | `true` | Container uses `UDim2.fromScale(1,1)` |
| `UseCanvas` | `boolean` | `false` | Wraps output in a `CanvasGroup` instead of `Frame` |
| `XAlignment` | `Enum.TextXAlignment` | `Left` | Horizontal alignment |
| `YAlignment` | `Enum.TextYAlignment` | `Top` | Vertical alignment |
| `Style` | `string \| table` | `nil` | Default enter animation style for all text |
| `Step` | `number` | `0.015` | Time between each character reveal (seconds) |
| `Speed` | `number` | `1` | Playback speed multiplier |
| `Chunks` | `number` | `1` | Characters revealed per step |
| `StepFactor` | `number` | `1` | Animation duration multiplier |
| `Amplitude` | `number` | `1` | Animation amplitude multiplier |
| `LetterStepped` | `function` | `nil` | Callback fired for each letter revealed: `(obj, char, word)` |
| `WordStepped` | `function` | `nil` | Callback fired for each word started: `(obj, word)` |
| `OnFinished` | `function` | `nil` | Callback fired when all text finishes animating: `(obj)` |

```lua
local obj = TextPlus.new("Hello world!", {
    Size = 18,
    Color = Color3.fromRGB(255, 220, 100),
    Style = "Fade",
    Step = 0.03,
    Wrapped = true,
    OnFinished = function(self)
        print("done")
    end,
})
```

---

## Tag Syntax

TextPlus uses `[text]<params>` blocks to style spans of text inline. Multiple blocks chain together. Plain text outside brackets uses the DefaultSettings.

### Basic Structure

```
[text]<key=value, key=value>
```

| Param Key | Type | Example | Description |
|---|---|---|---|
| `color` | Color3 | `color=rgb(255,0,0)` or `color=#FF0000` | Text color |
| `size` | number | `size=24` | Text size override |
| `font` | string | `font=GothamBold` | Font by name |
| `fontface` | string | `fontface=name(GothamBold,Bold,Normal)` | Full FontFace |
| `transparency` | number | `transparency=0.5` | Text transparency |
| `strokecolor` | Color3 | `strokecolor=rgb(0,0,0)` | Stroke color |
| `stroketransparency` | number | `stroketransparency=0` | Stroke transparency |
| `style` | string or table | `style=Fade` | Enter animation style |
| `step` | number | `step=0.05` | Per-character step time for this span |
| `speed` | number | `speed=2` | Speed multiplier for this span |
| `chunks` | number | `chunks=3` | Characters per step for this span |
| `amplitude` | number | `amplitude=2` | Animation amplitude for this span |
| `scale` | number | `scale=0.5` | Size scale when `Scaled = true` |
| `img` | string | `img=12345678` | Asset ID for an inline image (use `#` as placeholder) |

### Color Formats

```lua
-- RGB integers
"[text]<color=rgb(255, 100, 50)>"

-- Hex
"[text]<color=#FF6432>"

-- HSV
"[text]<color=hsv(0.5, 1, 1)>"
```

### Nesting

Blocks can nest — inner params inherit outer params and override specific fields:

```lua
"[Hello [world]<color=rgb(255,0,0)>]<size=20>"
-- "Hello" is size 20 white; "world" is size 20 red
```

### Escaped Brackets

Use `\[` to render a literal `[` character:

```lua
"Press \[E] to interact"
-- renders: Press [E] to interact
```

---

## Built-in Animation Styles

Styles are applied letter-by-letter as they are revealed during `:Play()`. During `:Print()`, styles apply all at once.

| Style | Effect |
|---|---|
| `Default` | Instant reveal — no animation, just sets color and transparency |
| `Fade` | Letters fade in from transparent to the target transparency |
| `Pop` | Letters spring-scale up from 0, settling at natural size |
| `Shrink` | Letters start oversized and shrink down to natural size |
| `Rise` | Letters slide upward into position |
| `Drop` | Letters slide downward into position |
| `Wiggle` | Letters oscillate vertically using a Bezier curve (loopable) |
| `Rainbow` | Letters cycle through rainbow colors as they animate in |

### Style Modifiers

Styles accept per-span modifier tables for looping, repeating, reversing, and timing:

```lua
-- Single style string
"[text]<style=Wiggle>"

-- Style with modifiers (table syntax in tag)
"[text]<style=(Wiggle, looped=true, amplitude=2)>"

-- Multiple styles applied in sequence
"[text]<style=(Fade, Rise)>"

-- Style with repeat count and reverse ping-pong
"[text]<style=(Pop, repeat=3, reverse=true)>"
```

| Modifier | Type | Description |
|---|---|---|
| `looped` | `boolean` | Loop the animation indefinitely |
| `reverse` | `boolean` | Ping-pong: play forward then backward |
| `repeat` | `number` | Play N times (`-1` = infinite, same as `looped`) |
| `stepfactor` | `number` | Stretch animation duration for this style |
| `delaytime` | `number` | Seconds to wait before starting this letter's animation |
| `amplitude` | `number` | Amplitude override for this style |

### DefaultSettings Style (applies to all text)

```lua
local obj = TextPlus.new("Hello!", {
    Style = "Fade",              -- simple string
})

local obj2 = TextPlus.new("Hello!", {
    Style = { "Fade", "Rise" },  -- multiple styles
})

local obj3 = TextPlus.new("Hello!", {
    Style = {                    -- style with modifiers
        { Style = "Wiggle", looped = true, amplitude = 1.5 }
    },
})
```

---

## Methods

### obj:Play(ParentFrame)

Renders text into `ParentFrame` character-by-character using `RunService.Heartbeat`. Returns `self, Container`.

**Requirements:** `ParentFrame` must be parented to the DataModel and have non-zero `AbsoluteSize.Y` before calling.

```lua
local obj = TextPlus.new("[Welcome!]<style=Rise, color=rgb(255,255,100)>", {
    Size = 20,
    Step = 0.04,
})
obj:Play(MyFrame)
```

### obj:Wait()

Yields the current coroutine until the typewriter animation finishes. Must be called while `:Play()` is running.

```lua
obj:Play(MyFrame)
obj:Wait()
-- continues here after all text has appeared
```

### obj:Print(ParentFrame)

Renders all text instantly — no per-character stepping. Destroys the object when done. Returns `Vector2` (content size).

```lua
local size = TextPlus.new("Score: 100", { Size = 16 }):Print(MyFrame)
```

**Note:** `:Print()` calls `:Destroy()` on itself when finished. Do not reuse the object after printing.

### obj:GetContentSize(ParentFrame)

Measures how much space the text would occupy inside `ParentFrame` without rendering visibly. Returns `Vector2`.

```lua
local size = TextPlus.new("Long string here...", { Size = 14 }):GetContentSize(MyFrame)
print(size.X, size.Y)
```

### obj:From(TextLabel, Exclusions?)

Copies text properties from an existing `TextLabel` into DefaultSettings. Chainable.

```lua
local obj = TextPlus.new("Hello"):From(existingLabel):Play(MyFrame)

-- Exclude specific properties from being copied
local obj = TextPlus.new("Hello"):From(existingLabel, {"Color", "Size"}):Play(MyFrame)
```

Copies: `TextSize → Size`, `TextColor3 → Color`, `TextTransparency → Transparency`, `TextStrokeColor3 → StrokeColor`, `TextStrokeTransparency → StrokeTransparency`, `FontFace → FontFace`, `TextXAlignment → XAlignment`, `TextYAlignment → YAlignment`.

### obj:Stop()

Stops the typewriter animation and fires `OnFinished`. Does not destroy the container or rendered text.

### obj:Destroy()

Fully destroys the object, disconnects `Heartbeat`, destroys the container frame, and clears all state. Always call this when done with a `:Play()` object.

```lua
local obj = TextPlus.new("..."):Play(MyFrame)
-- ... later
obj:Destroy()
```

### obj:GetIdValue(id)

Returns the stored value for a registered ID (see `TextPlus.RegisterId`).

---

## Static Methods

### TextPlus.RegisterId(Id, Content)

Registers a reusable value or function that can be referenced in tag strings with `#id`.

```lua
-- Static value
TextPlus.RegisterId("playername", function()
    return game.Players.LocalPlayer.Name
end)

-- Use in tag string
TextPlus.new("Hello, #playername!")
```

**Built-in IDs** (registered in `Storage.lua`):
- `#playername` — returns `LocalPlayer.Name`

### TextPlus.UnRegisterId(Id)

Removes a registered ID.

### TextPlus.RegisterStyle(Id, Function)

Registers a custom per-letter animation function.

```lua
TextPlus.RegisterStyle("MyStyle", function(
    Letter: TextLabel,
    Progress: number,         -- 0 to 1, animation progress
    Transparency: number,     -- target transparency
    StrokeTransparency: number,
    Color: Color3,
    StrokeColor: Color3,
    Size: UDim2,              -- letter's natural size
    Position: UDim2,          -- letter's natural position
    Amplitude: number?,
    Reversing: boolean?       -- true during reverse phase (ping-pong)
)
    -- modify Letter properties based on Progress
    Letter.TextTransparency = 1 - Progress
    Letter.Size = UDim2.fromScale(Size.X.Scale * Progress, Size.Y.Scale * Progress)
end)
```

Return `true` from the function to signal the animation is complete early.

### TextPlus.UnRegisterStyle(Id)

Removes a custom registered style.

### TextPlus.Format(Content)

Converts a Lua value (Color3, Font, EnumItem, table, string) into a TextPlus-compatible tag parameter string.

```lua
local colorStr = TextPlus.Format(Color3.fromRGB(255, 100, 50))
-- "rgb(255,100,50)"

local tagStr = TextPlus.Format({
    color = Color3.fromRGB(255, 0, 0),
    size = 20,
    style = "Fade",
})
-- "color = rgb(255,0,0),size = 20,style = Fade"
```

---

## Inline Images

Use `img=assetId` param and `#` as the image placeholder token:

```lua
TextPlus.new("[#]<img=12345678> Coin collected!", { Size = 24 }):Play(MyFrame)
```

The `#` token is replaced with an `ImageLabel` sized to match `Size`.

---

## Complete Examples

### Dialogue-style typewriter

```lua
local TextPlus = global.SharedModules["textplus"]

local obj = TextPlus.new(
    "[Hello, ]<color=rgb(200,200,200)>[#playername]<color=rgb(255,255,100), style=Pop>!",
    {
        Size = 18,
        Style = "Fade",
        Step = 0.04,
        Wrapped = true,
        OnFinished = function()
            -- show continue prompt
        end,
    }
)
obj:Play(DialogueFrame)
obj:Wait()
obj:Destroy()
```

### Instant print with size measurement

```lua
local size = TextPlus.new("Quest Complete!", {
    Size = 20,
    Color = Color3.fromRGB(100, 255, 100),
}):Print(TitleFrame)
-- TitleFrame auto-sizes to content
```

### Looping rainbow header

```lua
TextPlus.new("[ITAMI]<style=(Rainbow, looped=true), size=32>"):Play(HeaderFrame)
```

### Multi-style span

```lua
TextPlus.new(
    "[CRITICAL]<color=rgb(255,50,50), style=(Pop, Wiggle, looped=true), amplitude=1.5>",
    { Size = 22 }
):Play(HitLabel)
```

### Dialogue system usage

The dialogue system uses TextPlus tag strings directly as style prefixes. The pattern used throughout dialogue files:

```lua
local Style2 = "<Font=Merriweather><Color=White><AnimateStyle=Custom><AnimateStepFrequency=1><AnimateStyleTime=.35><AnimateStyle=Wiggle>"
-- This is Roblox rich text, not TextPlus tags — see DialogueConstructor

-- TextPlus is used separately when rendering dialogue text into frames
local obj = TextPlus.new(dialogueText, { Size = 14, Style = "Fade", Step = 0.025 })
obj:Play(DialogueTextFrame)
```

---

## Architecture Notes

- **Phase 1** (`TextPlusUtility.Phase1`): Parses the raw tag string into a sequence of `{Text, Params}` entries.
- **Phase 2** (`TextPlusUtility.Phase2`): Parses a param block string into a key-value table, handling nested brackets for complex values like `fontface=name(...)` and `style=(...)`.
- **AnimatorManager**: Called every `Heartbeat`. Steps through the sequence, creates word and letter `TextLabel`s, and dispatches to `AnimatorClass`.
- **AnimatorClass**: Tracks per-letter animation state, calls the active style function(s) each frame until `Progress >= WordLength`.
- **Container**: A `Frame` (or `CanvasGroup` if `UseCanvas=true`) named `"TextPlusTextHolder"` is created inside the parent frame. A `UIListLayout` with `FillDirection = Horizontal` and `Wraps = true` lays out word containers.
- **Termination**: When all sequence entries are consumed, `AnimatorManager` calls `Terminate`, which sets `__DeleteWhenDone` and destroys after all animations complete.
- `FayeTypes.Connection`