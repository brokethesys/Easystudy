#!/usr/bin/env python3
"""
Простой HTTP сервер для вопросов викторины и теории
Запуск: python server.py
Порт: 8080
"""

import json
import os
import random
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs, unquote
from datetime import datetime
import socket

class QuizRequestHandler(BaseHTTPRequestHandler):
    
    def __init__(self, *args, **kwargs):
        self.questions = self._load_questions()
        self.theory = self._load_theory()
        super().__init__(*args, **kwargs)
    
    def _set_headers(self, status_code=200):
        """Устанавливаем заголовки ответа"""
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.end_headers()
    
    def do_OPTIONS(self):
        """Обработка предварительных запросов CORS"""
        self._set_headers()
    
    def log_message(self, format, *args):
        """Кастомизируем логирование"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] {self.address_string()} - {format % args}")
    
    def _load_questions(self):
        """Загружает вопросы из нескольких JSON файлов"""
        question_files = [
            'chemistry.json',  # Химия -> Chemistry
            'math.json',       # Математика -> Math
            'history.json'     # История -> History
        ]
        
        all_questions = []
        
        for filename in question_files:
            try:
                if os.path.exists(filename):
                    with open(filename, 'r', encoding='utf-8') as f:
                        questions = json.load(f)
                        all_questions.extend(questions)
                        print(f"✅ Загружено {len(questions)} вопросов из {filename}")
                else:
                    print(f"⚠️  Файл {filename} не найден")
                    
            except json.JSONDecodeError as e:
                print(f"❌ Ошибка чтения {filename}: {e}")
            except Exception as e:
                print(f"❌ Неожиданная ошибка при загрузке {filename}: {e}")
        
        print(f"📊 Всего загружено {len(all_questions)} вопросов")
        
        # Проверяем предметы
        subjects = list(set([q.get('subject', 'Unknown') for q in all_questions]))
        print(f"📚 Предметы в базе: {subjects}")
        
        return all_questions
    
    def _load_theory(self):
        """Загружает теорию из нескольких JSON файлов"""
        theory_files = [
            'theory_chemistry.json',
            'theory_math.json', 
            'theory_history.json'
        ]
        
        all_theory = []
        
        for filename in theory_files:
            try:
                if os.path.exists(filename):
                    with open(filename, 'r', encoding='utf-8') as f:
                        theory = json.load(f)
                        all_theory.extend(theory)
                        print(f"✅ Загружено {len(theory)} блоков теории из {filename}")
                else:
                    print(f"⚠️  Файл теории {filename} не найден")
                    
            except json.JSONDecodeError as e:
                print(f"❌ Ошибка чтения теории {filename}: {e}")
            except Exception as e:
                print(f"❌ Неожиданная ошибка при загрузке теории {filename}: {e}")
        
        print(f"📚 Всего загружено {len(all_theory)} блоков теории")
        return all_theory
    
    def _get_subjects(self):
        """Возвращает список уникальных предметов"""
        subjects = list(set([q['subject'] for q in self.questions]))
        return sorted(subjects)
    
    def _get_categories(self, subject=None):
        """Возвращает категории для предмета или все категории"""
        if subject:
            categories = list(set([q['category'] for q in self.questions if q['subject'] == subject]))
        else:
            categories = list(set([q['category'] for q in self.questions]))
        return sorted(categories)
    
    def _get_questions_by_subject(self, subject, limit=None, shuffle=False):
        """Возвращает вопросы по предмету"""
        subject_questions = [q for q in self.questions if q['subject'] == subject]
        
        if shuffle:
            random.shuffle(subject_questions)
        
        if limit and limit > 0:
            subject_questions = subject_questions[:limit]
        
        return subject_questions
    
    def _get_questions_by_category(self, subject, category, limit=None, shuffle=False):
        """Возвращает вопросы по предмету и категории"""
        category_questions = [q for q in self.questions 
                             if q['subject'] == subject and q['category'] == category]
        
        if shuffle:
            random.shuffle(category_questions)
        
        if limit and limit > 0:
            category_questions = category_questions[:limit]
        
        return category_questions
    
    def _get_question_by_id(self, question_id):
        """Находит вопрос по ID"""
        for question in self.questions:
            if question['id'] == question_id:
                return question
        return None
    
    def _get_random_question(self, subject=None, category=None):
        """Возвращает случайный вопрос"""
        filtered_questions = self.questions
        
        if subject:
            filtered_questions = [q for q in filtered_questions if q['subject'] == subject]
        
        if category:
            filtered_questions = [q for q in filtered_questions if q['category'] == category]
        
        if not filtered_questions:
            return None
        
        return random.choice(filtered_questions)
    
    def _get_theory_by_subject(self, subject):
        """Возвращает теорию по предмету"""
        return [t for t in self.theory if t['subject'] == subject]
    
    def _get_theory_by_subject_and_block(self, subject, block_number):
        """Возвращает теорию по предмету и номеру блока"""
        for theory in self.theory:
            if theory['subject'] == subject and theory['block_number'] == block_number:
                return theory
        return None
    
    def _get_theory_stats(self):
        """Возвращает статистику по теории"""
        stats = {
            "total_blocks": len(self.theory),
            "subjects": {}
        }
        
        for subject in self._get_subjects():
            subject_theory = [t for t in self.theory if t['subject'] == subject]
            stats["subjects"][subject] = {
                "count": len(subject_theory),
                "blocks": sorted(list(set([t['block_number'] for t in subject_theory])))
            }
        
        return stats
    
    def _get_quiz_stats(self):
        """Возвращает статистику по вопросам"""
        stats = {
            "total_questions": len(self.questions),
            "subjects": {},
            "categories_by_subject": {}
        }
        
        # Статистика по предметам
        for subject in self._get_subjects():
            subject_questions = [q for q in self.questions if q['subject'] == subject]
            stats["subjects"][subject] = {
                "count": len(subject_questions),
                "categories": self._get_categories(subject),
                "difficulty_distribution": {
                    "easy": len([q for q in subject_questions if q.get('difficulty', 1) == 1]),
                    "medium": len([q for q in subject_questions if q.get('difficulty', 1) == 2]),
                    "hard": len([q for q in subject_questions if q.get('difficulty', 1) == 3])
                }
            }
        
        return stats
    
    def do_GET(self):
        """Обработка GET запросов"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        query_params = parse_qs(parsed_path.query)
        
        # Проверяем, загружены ли вопросы
        if not self.questions:
            response = {
                "status": "error",
                "message": "Вопросы не загружены. Проверьте файлы chemistry.json, math.json, history.json"
            }
            self._set_headers(500)
            self.wfile.write(json.dumps(response, ensure_ascii=False).encode('utf-8'))
            return
        
        # Обрабатываем разные пути
        try:
            if path == '/' or path == '/ping' or path == '/health':
                # Проверка работы сервера
                response = {
                    "status": "ok",
                    "message": "EasyStudy Quiz API работает",
                    "timestamp": datetime.now().isoformat(),
                    "server_ip": self._get_server_ip(),
                    "total_questions": len(self.questions),
                    "total_theory_blocks": len(self.theory),
                    "subjects": self._get_subjects(),
                    "endpoints": {
                        "/subjects": "Список всех предметов",
                        "/categories": "Все категории",
                        "/stats": "Статистика вопросов",
                        "/stats/theory": "Статистика теории",
                        "/questions": "Все вопросы (можно фильтровать)",
                        "/questions/subject/{subject}": "Вопросы по предмету",
                        "/questions/ordered/{subject}": "Вопросы по предмету в порядке ID",
                        "/questions/subject/{subject}/category/{category}": "Вопросы по предмету и категории",
                        "/question/{id}": "Вопрос по ID",
                        "/question/random": "Случайный вопрос",
                        "/quiz/{subject}/{count}": "Готовый тест из N вопросов",
                        "/theory": "Вся теория",
                        "/theory/subject/{subject}": "Теория по предмету",
                        "/theory/subject/{subject}/block/{block}": "Теория по предмету и блоку",
                        "/check": "POST: проверить ответ (тело: question_id, user_answer)"
                    }
                }
            
            elif path == '/subjects':
                # Список всех предметов
                subjects = self._get_subjects()
                response = {
                    "subjects": subjects,
                    "count": len(subjects)
                }
            
            elif path == '/categories':
                # Все категории или категории по предмету
                subject = query_params.get('subject', [None])[0]
                categories = self._get_categories(subject)
                response = {
                    "subject": subject,
                    "categories": categories,
                    "count": len(categories)
                }
            
            elif path == '/stats':
                # Статистика по вопросам
                response = self._get_quiz_stats()
            
            elif path == '/stats/theory':
                # Статистика по теории
                response = self._get_theory_stats()
            
            elif path == '/questions':
                # Все вопросы с возможностью фильтрации
                subject = query_params.get('subject', [None])[0]
                category = query_params.get('category', [None])[0]
                limit = query_params.get('limit', [None])[0]
                shuffle = query_params.get('shuffle', ['false'])[0].lower() == 'true'
                
                filtered_questions = self.questions
                
                if subject:
                    filtered_questions = [q for q in filtered_questions if q['subject'] == subject]
                
                if category:
                    filtered_questions = [q for q in filtered_questions if q['category'] == category]
                
                if shuffle:
                    random.shuffle(filtered_questions)
                
                if limit and limit.isdigit():
                    limit_int = int(limit)
                    filtered_questions = filtered_questions[:limit_int]
                
                # Убираем правильный ответ и объяснение для клиента
                questions_for_client = []
                for q in filtered_questions:
                    safe_q = q.copy()
                    if 'correct' in safe_q:
                        del safe_q['correct']
                    if 'explanation' in safe_q:
                        del safe_q['explanation']
                    questions_for_client.append(safe_q)
                
                response = {
                    "questions": questions_for_client,
                    "count": len(filtered_questions),
                    "filters": {
                        "subject": subject,
                        "category": category,
                        "limit": limit,
                        "shuffled": shuffle
                    }
                }
            
            elif path.startswith('/questions/ordered/'):
                # Вопросы по предмету В ПОРЯДКЕ ID (без перемешивания)
                parts = path.split('/')
                if len(parts) >= 4:
                    encoded_subject = parts[3]
                    subject = unquote(encoded_subject)
                    
                    limit = query_params.get('limit', [None])[0]
                    
                    subject_questions = self._get_questions_by_subject(
                        subject,
                        limit=int(limit) if limit and limit.isdigit() else None,
                        shuffle=False  # НЕ перемешиваем для порядка!
                    )
                    
                    # Сортируем по ID для гарантии порядка
                    subject_questions.sort(key=lambda x: x['id'])
                    
                    # Убираем правильный ответ для клиента
                    questions_for_client = []
                    for q in subject_questions:
                        safe_q = q.copy()
                        if 'correct' in safe_q:
                            del safe_q['correct']
                        if 'explanation' in safe_q:
                            del safe_q['explanation']
                        questions_for_client.append(safe_q)
                    
                    response = {
                        "subject": subject,
                        "questions": questions_for_client,
                        "count": len(subject_questions),
                        "ordered": True
                    }
                else:
                    response = {"error": "Не указан предмет"}
                    self._set_headers(400)
            
            elif path.startswith('/questions/subject/'):
                # Вопросы по предмету
                parts = path.split('/')
                if len(parts) >= 4:
                    # Декодируем название предмета из URL
                    encoded_subject = parts[3]
                    subject = unquote(encoded_subject)
                    
                    print(f"🔍 Запрос вопросов по предмету: '{subject}' (декодировано из '{encoded_subject}')")
                    
                    # Проверяем, есть ли категория
                    if len(parts) >= 6 and parts[4] == 'category':
                        encoded_category = parts[5]
                        category = unquote(encoded_category)
                        limit = query_params.get('limit', [None])[0]
                        shuffle = query_params.get('shuffle', ['false'])[0].lower() == 'true'
                        
                        print(f"  Категория: '{category}'")
                        
                        category_questions = self._get_questions_by_category(
                            subject, category, 
                            limit=int(limit) if limit and limit.isdigit() else None,
                            shuffle=shuffle
                        )
                        
                        # Убираем правильный ответ для клиента
                        questions_for_client = []
                        for q in category_questions:
                            safe_q = q.copy()
                            if 'correct' in safe_q:
                                del safe_q['correct']
                            if 'explanation' in safe_q:
                                del safe_q['explanation']
                            questions_for_client.append(safe_q)
                        
                        response = {
                            "subject": subject,
                            "category": category,
                            "questions": questions_for_client,
                            "count": len(category_questions)
                        }
                    else:
                        # Только предмет
                        limit = query_params.get('limit', [None])[0]
                        shuffle = query_params.get('shuffle', ['false'])[0].lower() == 'true'
                        
                        subject_questions = self._get_questions_by_subject(
                            subject,
                            limit=int(limit) if limit and limit.isdigit() else None,
                            shuffle=shuffle
                        )
                        
                        print(f"  Найдено вопросов: {len(subject_questions)}")
                        
                        # Убираем правильный ответ для клиента
                        questions_for_client = []
                        for q in subject_questions:
                            safe_q = q.copy()
                            if 'correct' in safe_q:
                                del safe_q['correct']
                            if 'explanation' in safe_q:
                                del safe_q['explanation']
                            questions_for_client.append(safe_q)
                        
                        response = {
                            "subject": subject,
                            "questions": questions_for_client,
                            "count": len(subject_questions),
                            "categories": self._get_categories(subject)
                        }
                else:
                    response = {"error": "Не указан предмет"}
                    self._set_headers(400)
            
            elif path.startswith('/question/random'):
                # Случайный вопрос
                subject = query_params.get('subject', [None])[0]
                category = query_params.get('category', [None])[0]
                
                question = self._get_random_question(subject, category)
                
                if question:
                    # Убираем правильный ответ для клиента
                    safe_question = question.copy()
                    if 'correct' in safe_question:
                        del safe_question['correct']
                    if 'explanation' in safe_question:
                        del safe_question['explanation']
                    
                    response = {"question": safe_question}
                else:
                    response = {"error": "Вопрос не найден"}
                    self._set_headers(404)
            
            elif path.startswith('/question/'):
                # Вопрос по ID
                try:
                    q_id = int(path.split('/')[-1])
                    question = self._get_question_by_id(q_id)
                    
                    if question:
                        response = {"question": question}
                    else:
                        response = {"error": f"Вопрос с ID {q_id} не найден"}
                        self._set_headers(404)
                except ValueError:
                    response = {"error": "Неверный формат ID вопроса"}
                    self._set_headers(400)
            
            elif path.startswith('/quiz/'):
                # Готовый тест
                parts = path.split('/')
                if len(parts) >= 4:
                    subject = parts[2]
                    try:
                        count = int(parts[3])
                        
                        # Получаем вопросы по предмету
                        subject_questions = self._get_questions_by_subject(subject, shuffle=True)
                        
                        if not subject_questions:
                            response = {"error": f"Нет вопросов по предмету '{subject}'"}
                            self._set_headers(404)
                        else:
                            # Берем нужное количество или все, если запрошено больше
                            quiz_questions = subject_questions[:min(count, len(subject_questions))]
                            
                            # Убираем правильный ответ для клиента
                            questions_for_quiz = []
                            for q in quiz_questions:
                                safe_q = q.copy()
                                if 'correct' in safe_q:
                                    del safe_q['correct']
                                if 'explanation' in safe_q:
                                    del safe_q['explanation']
                                questions_for_quiz.append(safe_q)
                            
                            response = {
                                "quiz": {
                                    "subject": subject,
                                    "questions": questions_for_quiz,
                                    "count": len(questions_for_quiz),
                                    "timestamp": datetime.now().isoformat()
                                }
                            }
                    except ValueError:
                        response = {"error": "Неверный формат количества вопросов"}
                        self._set_headers(400)
                else:
                    response = {"error": "Укажите предмет и количество вопросов: /quiz/{subject}/{count}"}
                    self._set_headers(400)
            
            # ===== НОВЫЕ ЭНДПОИНТЫ ДЛЯ ТЕОРИИ =====
            elif path == '/theory':
                # Вся теория
                subject = query_params.get('subject', [None])[0]
                block_number = query_params.get('block', [None])[0]
                
                filtered_theory = self.theory
                
                if subject:
                    filtered_theory = [t for t in filtered_theory if t['subject'] == subject]
                
                if block_number and block_number.isdigit():
                    block_int = int(block_number)
                    filtered_theory = [t for t in filtered_theory if t['block_number'] == block_int]
                
                response = {
                    "theory": filtered_theory,
                    "count": len(filtered_theory)
                }
            
            elif path.startswith('/theory/subject/'):
                parts = path.split('/')
                if len(parts) >= 4:
                    encoded_subject = parts[3]
                    subject = unquote(encoded_subject)
                    
                    # Проверяем, есть ли номер блока
                    if len(parts) >= 6 and parts[4] == 'block':
                        try:
                            block_number = int(parts[5])
                            theory = self._get_theory_by_subject_and_block(subject, block_number)
                            
                            if theory:
                                response = {"theory": theory}
                            else:
                                response = {"error": f"Теория для предмета '{subject}', блока {block_number} не найдена"}
                                self._set_headers(404)
                        except ValueError:
                            response = {"error": "Неверный формат номера блока"}
                            self._set_headers(400)
                    else:
                        # Только предмет
                        subject_theory = self._get_theory_by_subject(subject)
                        
                        if subject_theory:
                            response = {
                                "subject": subject,
                                "theory": subject_theory,
                                "count": len(subject_theory)
                            }
                        else:
                            response = {"error": f"Теория для предмета '{subject}' не найдена"}
                            self._set_headers(404)
                else:
                    response = {"error": "Не указан предмет"}
                    self._set_headers(400)
            
            else:
                # Неизвестный путь
                response = {
                    "error": "Endpoint не найден",
                    "available_endpoints": [
                        "/subjects",
                        "/questions",
                        "/questions/ordered/{subject}",
                        "/question/random",
                        "/quiz/{subject}/{count}",
                        "/theory",
                        "/theory/subject/{subject}",
                        "/theory/subject/{subject}/block/{block}"
                    ]
                }
                self._set_headers(404)
        
        except Exception as e:
            # Обработка ошибок
            response = {
                "error": "Внутренняя ошибка сервера",
                "details": str(e)
            }
            self._set_headers(500)
            print(f"❌ Ошибка при обработке запроса: {e}")
        
        # Отправляем ответ
        self._set_headers()
        self.wfile.write(json.dumps(response, ensure_ascii=False, indent=2).encode('utf-8'))
    
    def do_POST(self):
        """Обработка POST запросов (проверка ответов)"""
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            
            if content_length == 0:
                response = {"error": "Пустое тело запроса"}
                self._set_headers(400)
                self.wfile.write(json.dumps(response, ensure_ascii=False).encode('utf-8'))
                return
            
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            # Проверяем обязательные поля
            if 'question_id' not in data or 'user_answer' not in data:
                response = {"error": "Необходимы поля: question_id и user_answer"}
                self._set_headers(400)
                self.wfile.write(json.dumps(response, ensure_ascii=False).encode('utf-8'))
                return
            
            question_id = data['question_id']
            user_answer = data['user_answer']
            
            # Находим вопрос
            question = self._get_question_by_id(question_id)
            
            if not question:
                response = {"error": f"Вопрос с ID {question_id} не найден"}
                self._set_headers(404)
                self.wfile.write(json.dumps(response, ensure_ascii=False).encode('utf-8'))
                return
            
            # Проверяем ответ
            correct_answer = question.get('correct', -1)
            is_correct = user_answer == correct_answer
            
            # Формируем ответ
            response = {
                "is_correct": is_correct,
                "correct_answer": correct_answer,
                "explanation": question.get('explanation', ''),
                "question_id": question_id,
                "subject": question.get('subject', ''),
                "category": question.get('category', '')
            }
            
            # Добавляем статистику, если есть
            if 'options' in question:
                response['options_count'] = len(question['options'])
            
            self._set_headers()
        
        except json.JSONDecodeError:
            response = {"error": "Неверный формат JSON"}
            self._set_headers(400)
        
        except Exception as e:
            response = {
                "error": "Внутренняя ошибка сервера",
                "details": str(e)
            }
            self._set_headers(500)
            print(f"❌ Ошибка при обработке POST: {e}")
        
        # Отправляем ответ
        self.wfile.write(json.dumps(response, ensure_ascii=False).encode('utf-8'))
    
    def _get_server_ip(self):
        """Получает IP адрес сервера"""
        try:
            # Создаем временный сокет для определения IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "localhost"

def run_server(host='0.0.0.0', port=8080):
    """Запускает сервер"""
    server_address = (host, port)
    httpd = HTTPServer(server_address, QuizRequestHandler)
    
    print("=" * 60)
    print("🚀 EasyStudy Quiz & Theory API Server")
    print("=" * 60)
    print(f"📡 Сервер запущен на:")
    print(f"   Локально: http://localhost:{port}")
    print(f"   Для Android эмулятора: http://10.0.2.2:{port}")
    
    try:
        ip = socket.gethostbyname(socket.gethostname())
        print(f"   В сети:  http://{ip}:{port}")
    except:
        pass
    
    print("\n📚 Основные эндпоинты для вопросов:")
    print("   GET  /subjects                    - список предметов")
    print("   GET  /questions                   - все вопросы")
    print("   GET  /questions/ordered/{subject} - вопросы по предмету В ПОРЯДКЕ")
    print("   GET  /questions/subject/{subject} - вопросы по предмету")
    print("   GET  /question/random             - случайный вопрос")
    print("   GET  /quiz/{subject}/{N}         - тест из N вопросов")
    print("   POST /check                       - проверить ответ")
    
    print("\n📖 Основные эндпоинты для теории:")
    print("   GET  /theory                      - вся теория")
    print("   GET  /theory/subject/{subject}    - теория по предмету")
    print("   GET  /theory/subject/{subject}/block/{block} - теория по предмету и блоку")
    
    print("\n⚙️  Параметры запросов:")
    print("   ?limit=10        - ограничить количество")
    print("   ?shuffle=true    - перемешать вопросы")
    print("   ?subject=Math    - фильтр по предмету")
    
    print("\n📊 Для тестирования в браузере:")
    print(f"   http://localhost:{port}/questions/ordered/Math")
    print(f"   http://localhost:{port}/theory/subject/Chemistry")
    print(f"   http://localhost:{port}/theory/subject/Math/block/1")
    print(f"   http://localhost:{port}/subjects")
    
    print("\n🛑 Для остановки сервера нажмите Ctrl+C")
    print("=" * 60)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n👋 Сервер остановлен")
    except Exception as e:
        print(f"\n\n❌ Ошибка сервера: {e}")

if __name__ == '__main__':
    # Проверяем наличие файлов с вопросами
    required_files = ['chemistry.json', 'math.json', 'history.json']
    missing_files = []
    
    for filename in required_files:
        if not os.path.exists(filename):
            missing_files.append(filename)
    
    if missing_files:
        print("⚠️  Внимание: не найдены следующие файлы с вопросами:")
        for filename in missing_files:
            print(f"   - {filename}")
    
    # Проверяем наличие файлов с теорией
    theory_files = ['theory_chemistry.json', 'theory_math.json', 'theory_history.json']
    missing_theory = []
    
    for filename in theory_files:
        if not os.path.exists(filename):
            missing_theory.append(filename)
    
    if missing_theory:
        print("⚠️  Внимание: не найдены следующие файлы с теорией:")
        for filename in missing_theory:
            print(f"   - {filename}")
    
    if missing_files or missing_theory:
        print("Убедитесь, что находитесь в правильной папке.")
        print(f"Текущая папка: {os.getcwd()}")
        
        create_sample = input("\nСоздать недостающие файлы? (y/n): ")
        if create_sample.lower() == 'y':
            # Создаем недостающие файлы
            for filename in missing_files + missing_theory:
                if filename in missing_files:
                    # Создаем пример файлов с вопросами
                    if filename == 'chemistry.json':
                        sample_data = [{
                            "id": 1,
                            "subject": "Chemistry",
                            "category": "atomic_structure",
                            "question": "Кто открыл периодический закон химических элементов?",
                            "options": ["Менделеев", "Бор", "Резерфорд", "Лавуазье"],
                            "correct": 0,
                            "difficulty": 1,
                            "explanation": "Д.И. Менделеев открыл периодический закон в 1869 году"
                        }]
                    elif filename == 'math.json':
                        sample_data = [{
                            "id": 26,
                            "subject": "Math",
                            "category": "linear_algebra",
                            "question": "Что такое матрица?",
                            "options": ["Прямоугольная таблица чисел", "Функция двух переменных", "Скалярное произведение", "Дифференциальное уравнение"],
                            "correct": 0,
                            "difficulty": 1,
                            "explanation": "Матрица — это прямоугольная таблица чисел, символов или выражений"
                        }]
                    elif filename == 'history.json':
                        sample_data = [{
                            "id": 51,
                            "subject": "History",
                            "category": "17_century",
                            "question": "Какой период истории России называют Смутным временем?",
                            "options": ["1605–1613", "1598–1613", "1613–1649", "1584–1598"],
                            "correct": 1,
                            "difficulty": 2,
                            "explanation": "Смутное время — период с 1598 по 1613 год"
                        }]
                else:
                    # Создаем пример файлов с теорией
                    if filename == 'theory_chemistry.json':
                        sample_data = [{
                            "block_number": 1,
                            "subject": "Chemistry",
                            "title": "Атомное строение вещества и периодический закон",
                            "content": "Теория по химии для блока 1..."
                        }]
                    elif filename == 'theory_math.json':
                        sample_data = [{
                            "block_number": 1,
                            "subject": "Math",
                            "title": "Линейная алгебра",
                            "content": "Теория по математике для блока 1..."
                        }]
                    elif filename == 'theory_history.json':
                        sample_data = [{
                            "block_number": 1,
                            "subject": "History",
                            "title": "XVII век в истории России",
                            "content": "Теория по истории для блока 1..."
                        }]
                
                with open(filename, 'w', encoding='utf-8') as f:
                    json.dump(sample_data, f, ensure_ascii=False, indent=2)
                print(f"✅ Создан пример {filename}")
    else:
        print("✅ Все файлы найдены")
    
    # Запускаем сервер
    run_server(host='0.0.0.0', port=8080)