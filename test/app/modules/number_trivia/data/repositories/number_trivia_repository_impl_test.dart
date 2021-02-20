import 'package:dartz/dartz.dart';
import 'package:flutter_tdd/app/core/error/exceptions.dart';
import 'package:flutter_tdd/app/core/error/failures.dart';
import 'package:flutter_tdd/app/core/network/network_info.dart';
import 'package:flutter_tdd/app/modules/number_trivia/data/datasources/number_trivia_local_datasource.dart';
import 'package:flutter_tdd/app/modules/number_trivia/data/datasources/number_trivia_remote_datasource.dart';
import 'package:flutter_tdd/app/modules/number_trivia/data/models/number_trivia_model.dart';
import 'package:flutter_tdd/app/modules/number_trivia/data/repositories/number_trivia_repository_impl.dart';
import 'package:flutter_tdd/app/modules/number_trivia/domain/entities/number_trivia.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockRemoteDataSource extends Mock
    implements NumberTriviaRemoteDataSource {}

class MockLocalDataSource extends Mock implements NumberTriviaLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  NumberTriviaRepositoryImpl repository;
  MockRemoteDataSource mockRemoteDataSource;
  MockLocalDataSource mockLocalDataSource;
  MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = NumberTriviaRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getConcreteNumberTrivia', () {
    final testNumber = 1;
    final testNumberTriviaModel =
        NumberTriviaModel(number: testNumber, text: 'test trivia');
    final NumberTrivia testNumberTrivia = testNumberTriviaModel;
    test('should check if the device is online', () async {
      // arrange
      // we arrange to return true every time when called
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      // act
      repository.getConcreteNumberTrivia(testNumber);
      // assert
      verify(mockNetworkInfo.isConnected);
    });

    void runTestOnline(Function body) {
      group('device is online', () {
        setUp(() {
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        });
        body();
      });
    }

    void runTestOffline(Function body) {
      group('device is offline', () {
        setUp(() {
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        });
        body();
      });
    }

    runTestOnline(() {
      test(
          'should return remote data when the call to remote data source is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.getConcreteNumberTrivia(any))
            .thenAnswer((_) async => testNumberTriviaModel);
        // act
        final result = await repository.getConcreteNumberTrivia(testNumber);
        // assert
        verify(mockRemoteDataSource.getConcreteNumberTrivia(testNumber));
        expect(result, equals(Right(testNumberTrivia)));
      });
      test(
          'should cache the data locally when the call to remote data source is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.getConcreteNumberTrivia(any))
            .thenAnswer((_) async => testNumberTriviaModel);
        // act
        await repository.getConcreteNumberTrivia(testNumber);
        // assert
        verify(mockRemoteDataSource.getConcreteNumberTrivia(testNumber));
        verify(mockLocalDataSource.cacheNumberTrivia(testNumberTriviaModel));
      });

      test(
          'should return server failure when the call to remote data source is unsuccessful',
          () async {
        // arrange
        when(mockRemoteDataSource.getConcreteNumberTrivia(any))
            .thenThrow((ServerException()));
        // act
        final result = await repository.getConcreteNumberTrivia(testNumber);
        // assert
        verify(mockRemoteDataSource.getConcreteNumberTrivia(testNumber));
        verifyZeroInteractions(
            mockLocalDataSource); // no method should be called
        expect(result, equals(Left(ServerFailure())));
      });
    });

    runTestOffline(() {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });
      test(
          'should return the last cached locally data when the cache data is present',
          () async {
        // arrange
        when(mockLocalDataSource.getLastNumberTrivia())
            .thenAnswer((_) async => testNumberTriviaModel);
        // act
        final result = await repository.getConcreteNumberTrivia(testNumber);
        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getLastNumberTrivia());
        expect(result, equals(Right(testNumberTrivia)));
      });
      test('should return CacheFaillure when there is no cached data present',
          () async {
        // arrange
        when(mockLocalDataSource.getLastNumberTrivia())
            .thenThrow(CacheException());
        // act
        final result = await repository.getConcreteNumberTrivia(testNumber);
        // assert
        expect(result, equals(Left(CacheFailure())));
        verifyZeroInteractions(mockRemoteDataSource);
      });
    });
  });

  group('getRandomNumberTrivia', () {
    final testNumberTriviaModel =
        NumberTriviaModel(number: 123, text: 'test trivia');
    final NumberTrivia testNumberTrivia = testNumberTriviaModel;
    test('should check if the device is online', () async {
      // arrange
      // we arrange to return true every time when called
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      // act
      repository.getRandomNumberTrivia();
      // assert
      verify(mockNetworkInfo.isConnected);
    });

    void runTestOnline(Function body) {
      group('device is online', () {
        setUp(() {
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        });
        body();
      });
    }

    void runTestOffline(Function body) {
      group('device is offline', () {
        setUp(() {
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        });
        body();
      });
    }

    runTestOnline(() {
      test(
          'should return remote data when the call to remote data source is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.getRandomNumberTrivia())
            .thenAnswer((_) async => testNumberTriviaModel);
        // act
        final result = await repository.getRandomNumberTrivia();
        // assert
        verify(mockRemoteDataSource.getRandomNumberTrivia());
        expect(result, equals(Right(testNumberTrivia)));
      });
      test(
          'should cache the data locally when the call to remote data source is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.getRandomNumberTrivia())
            .thenAnswer((_) async => testNumberTriviaModel);
        // act
        await repository.getRandomNumberTrivia();
        // assert
        verify(mockRemoteDataSource.getRandomNumberTrivia());
        verify(mockLocalDataSource.cacheNumberTrivia(testNumberTriviaModel));
      });

      test(
          'should return server failure when the call to remote data source is unsuccessful',
          () async {
        // arrange
        when(mockRemoteDataSource.getRandomNumberTrivia())
            .thenThrow((ServerException()));
        // act
        final result = await repository.getRandomNumberTrivia();
        // assert
        verify(mockRemoteDataSource.getRandomNumberTrivia());
        verifyZeroInteractions(
            mockLocalDataSource); // no method should be called
        expect(result, equals(Left(ServerFailure())));
      });
    });

    runTestOffline(() {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });
      test(
          'should return the last cached locally data when the cache data is present',
          () async {
        // arrange
        when(mockLocalDataSource.getLastNumberTrivia())
            .thenAnswer((_) async => testNumberTriviaModel);
        // act
        final result = await repository.getRandomNumberTrivia();
        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getLastNumberTrivia());
        expect(result, equals(Right(testNumberTrivia)));
      });
      test('should return CacheFaillure when there is no cached data present',
          () async {
        // arrange
        when(mockLocalDataSource.getLastNumberTrivia())
            .thenThrow(CacheException());
        // act
        final result = await repository.getRandomNumberTrivia();
        // assert
        expect(result, equals(Left(CacheFailure())));
        verifyZeroInteractions(mockRemoteDataSource);
      });
    });
  });
}
