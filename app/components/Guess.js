import React from "react";
import { Button, View, Text, TextInput } from "react-native";
import TimerCountdown from "react-native-timer-countdown";

export default class Guess extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      guess: ""
    }
  }

  render() {

    return (
      <View style={styles.mainContent}>
        <TimerCountdown
          initialMilliseconds={1000 * 300}
          onExpire={this.props.handleTimeUp}
          formatMilliseconds={(milliseconds) => {
            const remainingSec = Math.round(milliseconds / 1000);
            const seconds = parseInt((remainingSec % 60).toString(), 10);
            const minutes = parseInt(((remainingSec / 60) % 60).toString(), 10);
            const hours = parseInt((remainingSec / 3600).toString(), 10);
            const s = seconds < 10 ? '0' + seconds : seconds;
            const m = minutes < 10 ? '0' + minutes : minutes;
            let h = hours < 10 ? '0' + hours : hours;
            h = h === '00' ? '' : h + ':';
            return h + m + ':' + s;
          }}
          allowFontScaling={true}
          style={{ fontSize: 20, color: 'black' }}
        />
        <Text style={styles.label}>To name {this.props.guessType === 'movie' ? this.props.previousGuess.length ? `a movie that ${this.props.previousGuess} was in.` : `a movie.` : this.props.previousGuess.length ? `an actor or actress in ${this.props.previousGuess}.` : `an actor or actress.`}</Text>
        <TextInput
          style={styles.text_field}
          onChangeText={guess => {
            this.setState({ guess: guess });
          }}
          value={this.state.guess}
          placeholder={`Pick ${this.props.guessType === 'movie' ? 'a movie' : 'an actor or actress'}`}
        />
        {this.state.guess.length ? <Button onPress={() => this.props.handleGuess(this.state.guess)} title="Enter" color="#0064e1" /> : null }
      </View>
    );
  }
}

const styles = {
  mainContent: {
    flex: 1,
    justifyContent: 'top',
    alignItems: 'center',
    textAlign: 'center',
    width: '100%'
  },
  label: {
    marginBottom: 5,
    fontSize: 15,
    fontWeight: "bold",
    color: "#333"
  },
  text_field: {
    width: 200,
    height: 40,
    borderColor: "#bfbfbf",
    borderWidth: 1,
    padding: 10,
    marginBottom: 10
  }
};
