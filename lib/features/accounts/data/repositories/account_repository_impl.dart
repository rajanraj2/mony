import '../../domain/models/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_dao.dart';

class AccountRepositoryImpl implements IAccountRepository {
  final AccountDao _dao;

  AccountRepositoryImpl(this._dao);

  @override
  Stream<List<Account>> watchAllAccounts() => _dao.watchAccounts();

  @override
  Future<List<Account>> getAllAccounts() => _dao.getAllAccounts();

  @override
  Future<Account?> getAccountById(String id) => _dao.getAccountById(id);

  @override
  Future<void> createAccount(Account account) => _dao.insertAccount(account);

  @override
  Future<void> updateAccount(Account account) => _dao.updateAccount(account);

  @override
  Future<void> deleteAccount(String id) => _dao.deleteAccount(id);

  @override
  Future<double> getAccountBalance(String id) async {
    final acc = await _dao.getAccountById(id);
    return acc?.currentBalance ?? 0.0;
  }
}
