# Page Factory

An experimental Radiant extension for defining content types/page templates. The intent is to stay light and reuse instead of rebuild.

There are three basic questions when dealing with content types in any CMS:

+ Content Definition: what parts make up a particular kind of page?
+ Templating: what's the markup for each set of parts?
+ Versioning: how do we track and share changes to definitions & templates?

Page Factory is meant to address the first point, defining pages. Templating and versioning can be achieved with existing extensions (Nested Layouts and File System Resources) and don't need to be reinvented.

## Goals

I'm using the name "Page Factory" very deliberately. A content type applies to your page throughout its lifespan and to some extent dictates what you can and cannot do with that page.

I'm taking a different approach. I want a _factory_ that only cares about setting up new pages, and doesn't make any page modifications until I tell it to. I want to retain all of the flexibility that comes with Radiant.

I want the following behaviors in my solution:

### Flexibility

I want my factories to set up pages for me and then stay out of my way. Having factories shouldn't prevent me from creating a Plain Old Page with my own choice of parts; nor should they prevent me from modifying pages after they're created.

### Simplicity

Page factories shouldn't fundamentally alter the way Pages work. I don't want to overload the `:body` part for use as a layout container. And I want to use regular Ruby to manage my factories. A Page factory should be a normal class; I should be able to inherit or extend it.

### Modularity

I want my factories to respect the division between presentation and behavior. Factories can _suggest_ a Page class, but shouldn't prevent you from changing that class on new or existing records. I'd like to take a similar approach to layouts -- flexibility is a requirement, not an enhancement.

## Some use cases

In addition to the basic use as way of defining content types, there are some specific cases I want Page Factory to address:

### Generic pages

I want to add a one-off page somewhere. In the past, generic pages have been catch-all content types with enough parts to fit any use case. They're ugly and hard to use.

I should be able to add a Plain Old Page without setting up a content type first. I should be able to add just the parts I need. I should be able to use the 'body' part to hold its layout, just like normal Radiant usage.

### Edge case

There's a page that needs to look or behave just a little differently from others of its kind. Instead of making its content type pull double duty, or creating a content type to handle a single page, I should be able to switch this page to a different layout. Or use a different page class. Or add a single page part to it.

Page factories shouldn't have an opinion about any of these attributes until you tell it to take action on a page or set of pages.

## Notes on implementation

+   **Syncing.** There needs to be some way to copy modifications from the factory to the pages in the database. Because I'm not exposing these factories in the Admin UI, there's no need to do this in real-time. I may take a note from File System Resources and add a rake task that makes sure each page has the proper parts according to its factory.

    There may need to be two tasks: one that only adds missing parts (soft sync) and one that both adds missing parts and removes vestigial parts (hard sync.) This is obviously incompatible with adding parts on the fly, but so be it. 
    
    One workaround would be to make sync tasks ignore Plain Old Pages so that you have at least one type of Page that's always open to modification.

+   **Part inheritance.** I'd like it if parts were inheritable among factories. The base factory should get its parts from `Radiant::Config['defaults.page.parts]` and its subclasses should inherit these. The parts array has to remain mutable for addition/removal/overrides.

+   **Modelling.** Initially I really wanted the Page factory to be a non-DB model. But I realize that Pages need to retain some association to their initial factory so that we can sync parts as changes are made to the factory.

    Should it be possible to change a page's factory after creation? Ideally, the Factory class is decoupled to the point that there shouldn't be a reason not to. Again, flexibility should be preserved wherever possible.

+   **Part definitions.** In addition to the part name, I'd like the ability to add a default value and some help/descriptive text.