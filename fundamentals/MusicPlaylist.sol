pragma solidity ^0.8.0;

contract MusicPlaylist {
    struct Song {
        string songName;
        string artist;
        string recordLabel;
        string audioLink;
        string lyricsLink;
        uint16 yearPublished;
    }

    mapping(address => Song[]) addressToPlaylist;

    function _addSong(string memory _songName, string memory _artist, string memory _recordLabel, string memory _audioLink, string memory _lyricsLink, uint16 _yearPublished) private {
        addressToPlaylist[msg.sender].push(Song(_songName, _artist, _recordLabel, _audioLink, _lyricsLink, _yearPublished));
    }

    function addSong(string memory _songName, string memory _artist, string memory _recordLabel, string memory _audioLink, string memory _lyricsLink, uint16 _yearPublished) public {
        require(bytes(_songName).length > 0, "Song Name Cannot Be Empty");
        require(bytes(_artist).length > 0, "Artist Name Cannot Be Empty");
        require(bytes(_audioLink).length > 0, "Audio Link Cannot Be Empty");
        _addSong(_songName, _artist, _recordLabel, _audioLink, _lyricsLink, _yearPublished);
    }
}
