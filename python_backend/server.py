#!/usr/bin/env python3
"""
Простой HTTP сервер для вопросов викторины
Запуск: python server.py
Порт: 8080
"""

import json
import os
import random
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from datetime import datetime
import socket

class QuizRequestHandler(BaseHTTPRequestHandler):
    
    def __init__(self, *args, **kwargs):
        self.questions = self._load_questions()
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
        """Загружает вопросы из JSON файла"""
        try:
            with open('questions.json', 'r', encoding='utf-8') as f:
                questions = json.load(f)
            print(f"✅ Загружено {len(questions)} вопросов из questions.json")
            return questions
        except FileNotFoundError:
            print("❌ Файл questions.json не найден!")
            return []
        except json.JSONDecodeError as e:
            print(f"❌ Ошибка чтения JSON: {e}")
            return []
        except Exception as e:
            print(f"❌ Неожиданная ошибка: {e}")
            return []
    
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
                "message": "Вопросы не загружены. Проверьте файл questions.json"
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
                    "endpoints": {
                        "/subjects": "Список всех предметов",
                        "/categories": "Все категории",
                        "/stats": "Статистика вопросов",
                        "/questions": "Все вопросы (можно фильтровать)",
                        "/questions/subject/{subject}": "Вопросы по предмету",
                        "/questions/subject/{subject}/category/{category}": "Вопросы по предмету и категории",
                        "/question/{id}": "Вопрос по ID",
                        "/question/random": "Случайный вопрос",
                        "/quiz/{subject}/{count}": "Готовый тест из N вопросов",
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
            
            elif path.startswith('/questions/subject/'):
                # Вопросы по предмету
                parts = path.split('/')
                if len(parts) >= 4:
                    subject = parts[3]
                    
                    # Проверяем, есть ли категория
                    if len(parts) >= 6 and parts[4] == 'category':
                        category = parts[5]
                        limit = query_params.get('limit', [None])[0]
                        shuffle = query_params.get('shuffle', ['false'])[0].lower() == 'true'
                        
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
            
            else:
                # Неизвестный путь
                response = {
                    "error": "Endpoint не найден",
                    "available_endpoints": [
                        "/subjects",
                        "/questions",
                        "/question/random",
                        "/quiz/{subject}/{count}"
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

def run_server(port=8080):
    """Запускает сервер"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, QuizRequestHandler)
    
    print("=" * 60)
    print("🚀 EasyStudy Quiz API Server")
    print("=" * 60)
    print(f"📡 Сервер запущен на:")
    print(f"   Локально: http://localhost:{port}")
    
    try:
        ip = socket.gethostbyname(socket.gethostname())
        print(f"   В сети:  http://{ip}:{port}")
    except:
        pass
    
    print("\n📚 Основные эндпоинты:")
    print("   GET  /subjects              - список предметов")
    print("   GET  /questions             - все вопросы")
    print("   GET  /questions/subject/{subject} - вопросы по предмету")
    print("   GET  /question/random       - случайный вопрос")
    print("   GET  /quiz/{subject}/{N}   - тест из N вопросов")
    print("   POST /                      - проверить ответ")
    
    print("\n⚙️  Параметры запросов:")
    print("   ?limit=10        - ограничить количество")
    print("   ?shuffle=true    - перемешать вопросы")
    print("   ?subject=Математика - фильтр по предмету")
    
    # В функции run_server изменим примеры:
    print("\n📊 Для тестирования в браузере:")
    print(f"   http://localhost:{port}/questions/subject/Chemistry")
    print(f"   http://localhost:{port}/quiz/Math/5")    
    
    print("\n🛑 Для остановки сервера нажмите Ctrl+C")
    print("=" * 60)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n👋 Сервер остановлен")
    except Exception as e:
        print(f"\n\n❌ Ошибка сервера: {e}")

if __name__ == '__main__':
    # Проверяем наличие файла с вопросами
    if not os.path.exists('questions.json'):
        print("⚠️  Внимание: файл questions.json не найден!")
        print("   Создайте его или убедитесь, что находитесь в правильной папке.")
        print("   Текущая папка:", os.getcwd())
        
        # Создаем пример файла
        sample_data = [
            {
                "id": 1,
                "subject": "Math",
                "category": "пример",
                "question": "Пример вопроса?",
                "options": ["Вариант A", "Вариант B", "Вариант C", "Вариант D"],
                "correct": 0,
                "difficulty": 1,
                "explanation": "Пример объяснения"
            }
        ]
        
        create_sample = input("Создать пример questions.json? (y/n): ")
        if create_sample.lower() == 'y':
            with open('questions.json', 'w', encoding='utf-8') as f:
                json.dump(sample_data, f, ensure_ascii=False, indent=2)
            print("✅ Создан пример questions.json")
    
    # Запускаем сервер
    run_server(port=8080)