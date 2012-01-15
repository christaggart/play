module Play
  class Song
    
    # The persistent ID of the song in the player's database.
    attr_accessor :id

    # The song's title. We use `name` as a stand-in for `title` to stay
    # consistent with Artist and Album names.
    attr_accessor :name

    # The song's String artist value.
    attr_accessor :artist

    # The song's String album value.
    attr_accessor :album

    # The song's Boolean starred value. Is this song starred? This is a special
    # attribute since it's usually never populated or accessed until directly
    # before serving as JSON, in which this attribute is populated by whether
    # the current_user has starred this song.
    attr_accessor :starred

    # Initializes a new Song.
    #
    # options - One of two possible arguments:
    #           Song.new('2799A5071CD3E516') # creates from a persistent_id
    #           Song.new(args)               # `args` is a Hash of attributes
    #
    # Returns a new Song instance.
    def initialize(options)
      if options.kind_of?(String)
        song = Song.find(options)
        @id     = song.id
        @name   = song.name
        @artist = song.artist
        @album  = song.album
      else
        @id     = options[:id]
        @name   = options[:name]
        @artist = options[:artist]
        @album  = options[:album]
      end
    end

    # Finds a song in the database.
    #
    # id - The persistent String ID in the player's database.
    #
    # Returns an instance of a Song.
    def self.find(id)
      record = Player.library.tracks[Appscript.its.persistent_ID.eq(id)].get[0]

      return nil if record.nil?

      new :id     => record.persistent_ID.get,
          :name   => record.name.get,
          :artist => record.artist.get,
          :album  => record.album.get
    end

    # The Appscript record.
    #
    # Returns an Appscript::Reference to this song.
    #
    # If we have an ID for this song, let's use that to find it (preferred,
    # since that'll be quick). If not, search through a combination Artist +
    # Song name match and return that record.
    def record
      if id
        Player.library.tracks[Appscript.its.persistent_ID.eq(id)].get[0]
      else
        Artist.new(artist).songs.select{|song| song.name =~ /^#{name}$/i}.first.record
      end
    end

    # The raw data of the album art provided for this song.
    #
    # Returns a String of the binary image or some shit. If there's no art
    # available, returns nil.
    def album_art_data
      record.artworks.get.empty? ? nil : record.artworks[1].raw_data.get.data
    end

    # The playcount for this song.
    #
    # Returns an Integer.
    def playcount
      History.count_by_song(self)
    end

    # The ID tells the tale.
    #
    # Returns a Boolean, duh.
    def ==(song)
      self.id == song.id
    end

    # Is this song queued up to play?
    #
    # Returns a Boolean.
    def queued?
      Play::Queue.queued?(self)
    end

    # The path on disk to this song.
    #
    # Returns a String.
    def path
      record.location.get.to_s
    end

    # The JSON representation of a Song, suitable for API responses.
    #
    # Returns a String-encoded JSON fragment.
    def to_json
      hash = {
        :id      => id,
        :name    => name,
        :artist  => artist,
        :album   => album,
        :starred => starred || false,
        :queued  => queued?
      }
      Yajl.dump hash
    end

  end
end